require 'spec_helper'

describe 'Issuable counts caching', :use_clean_rails_memory_store_caching do
  let!(:member) { create(:user) }
  let!(:member_2) { create(:user) }
  let!(:non_member) { create(:user) }
  let!(:project) { create(:empty_project, :public) }
  let!(:open_issue) { create(:issue, project: project) }
  let!(:confidential_issue) { create(:issue, :confidential, project: project, author: non_member) }
  let!(:closed_issue) { create(:issue, :closed, project: project) }

  before do
    project.add_developer(member)
    project.add_developer(member_2)
  end

  it 'caches issuable counts correctly for non-members' do
    # We can't use expect_any_instance_of because that uses a single instance.
    counts = 0

    allow_any_instance_of(IssuesFinder).to receive(:count_by_state).and_wrap_original do |m, *args|
      counts += 1

      m.call(*args)
    end

    aggregate_failures 'only counts once on first load with no params, and caches for later loads' do
      expect { visit project_issues_path(project) }
        .to change { counts }.by(1)

      expect { visit project_issues_path(project) }
        .not_to change { counts }
    end

    aggregate_failures 'uses counts from cache on load from non-member' do
      sign_in(non_member)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_out(non_member)
    end

    aggregate_failures 'does not use the same cache for a member' do
      sign_in(member)

      expect { visit project_issues_path(project) }
        .to change { counts }.by(1)

      sign_out(member)
    end

    aggregate_failures 'uses the same cache for all members' do
      sign_in(member_2)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_out(member_2)
    end

    aggregate_failures 'shares caches when params are passed' do
      expect { visit project_issues_path(project, author_username: non_member.username) }
        .to change { counts }.by(1)

      sign_in(member)

      expect { visit project_issues_path(project, author_username: non_member.username) }
        .to change { counts }.by(1)

      sign_in(non_member)

      expect { visit project_issues_path(project, author_username: non_member.username) }
        .not_to change { counts }

      sign_in(member_2)

      expect { visit project_issues_path(project, author_username: non_member.username) }
        .not_to change { counts }

      sign_out(member_2)
    end

    aggregate_failures 'resets caches on issue close' do
      Issues::CloseService.new(project, member).execute(open_issue)

      expect { visit project_issues_path(project) }
        .to change { counts }.by(1)

      sign_in(member)

      expect { visit project_issues_path(project) }
        .to change { counts }.by(1)

      sign_in(non_member)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_in(member_2)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_out(member_2)
    end

    aggregate_failures 'does not reset caches on issue update' do
      Issues::UpdateService.new(project, member, title: 'new title').execute(open_issue)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_in(member)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_in(non_member)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_in(member_2)

      expect { visit project_issues_path(project) }
        .not_to change { counts }

      sign_out(member_2)
    end
  end
end
