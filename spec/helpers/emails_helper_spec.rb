require 'spec_helper'

describe EmailsHelper do
  describe 'password_reset_token_valid_time' do
    def validate_time_string(time_limit, expected_string)
      Devise.reset_password_within = time_limit
      expect(password_reset_token_valid_time).to eq(expected_string)
    end

    context 'when time limit is less than 2 hours' do
      it 'displays the time in hours using a singular unit' do
        validate_time_string(1.hour, '1 hour')
      end
    end

    context 'when time limit is 2 or more hours' do
      it 'displays the time in hours using a plural unit' do
        validate_time_string(2.hours, '2 hours')
      end
    end

    context 'when time limit contains fractions of an hour' do
      it 'rounds down to the nearest hour' do
        validate_time_string(96.minutes, '1 hour')
      end
    end

    context 'when time limit is 24 or more hours' do
      it 'displays the time in days using a singular unit' do
        validate_time_string(24.hours, '1 day')
      end
    end

    context 'when time limit is 2 or more days' do
      it 'displays the time in days using a plural unit' do
        validate_time_string(2.days, '2 days')
      end
    end

    context 'when time limit contains fractions of a day' do
      it 'rounds down to the nearest day' do
        validate_time_string(57.hours, '2 days')
      end
    end
  end

  describe '#header_logo' do
    context 'there is a brand item with a logo' do
      it 'returns the brand header logo' do
        appearance = create :appearance, header_logo: fixture_file_upload('spec/fixtures/dk.png')

        expect(header_logo).to eq(
          %{<img style="height: 50px" src="/uploads/-/system/appearance/header_logo/#{appearance.id}/dk.png" alt="Dk" />}
        )
      end
    end

    context 'there is a brand item without a logo' do
      it 'returns the default header logo' do
        create :appearance, header_logo: nil

        expect(header_logo).to eq(
          %{<img alt="GitLab" src="/images/mailers/gitlab_header_logo.gif" width="55" height="50" />}
        )
      end
    end

    context 'there is no brand item' do
      it 'returns the default header logo' do
        expect(header_logo).to eq(
          %{<img alt="GitLab" src="/images/mailers/gitlab_header_logo.gif" width="55" height="50" />}
        )
      end
    end
  end

  describe '#create_list_id_string' do
    using RSpec::Parameterized::TableSyntax

    where(:full_path, :list_id_path) do
      "01234"  | "01234"
      "5/0123" | "012.."
      "45/012" | "012.."
      "012"    | "012"
      "23/01"  | "01.23"
      "2/01"   | "01.2"
      "234/01" | "01.."
      "4/2/0"  | "0.2.4"
      "45/2/0" | "0.2.."
      "5/23/0" | "0.."
      "0-2/5"  | "5.0-2"
      "0_2/5"  | "5.0-2"
      "0.2/5"  | "5.0-2"
    end

    with_them do
      it 'ellipcizes different variants' do
        project = double("project")
        allow(project).to receive(:full_path).and_return(full_path)
        allow(project).to receive(:id).and_return(12345)
        # Set a max length that gives only 5 chars for the project full path
        max_length = "12345..#{Gitlab.config.gitlab.host}".length + 5
        list_id = create_list_id_string(project, max_length)

        expect(list_id).to eq("12345.#{list_id_path}.#{Gitlab.config.gitlab.host}")
        expect(list_id).to satisfy { |s| s.length <= max_length }
      end
    end
  end

  describe 'Create realistic List-Id identifier' do
    using RSpec::Parameterized::TableSyntax

    where(:full_path, :list_id_path) do
      "gitlab-org/gitlab-ce" | "gitlab-ce.gitlab-org"
      "project-name/subproject_name/my.project" | "my-project.subproject-name.project-name"
    end

    with_them do
      it 'Produces the right List-Id' do
        project = double("project")
        allow(project).to receive(:full_path).and_return(full_path)
        allow(project).to receive(:id).and_return(12345)
        list_id = create_list_id_string(project)

        expect(list_id).to eq("12345.#{list_id_path}.#{Gitlab.config.gitlab.host}")
        expect(list_id).to satisfy { |s| s.length <= 255 }
      end
    end
  end
end
