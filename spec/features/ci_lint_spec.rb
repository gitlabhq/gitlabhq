require 'spec_helper'

describe 'CI Lint', js: true do
  before do
    sign_in(create(:user))
  end

  describe 'YAML parsing' do
    before do
      visit ci_lint_path
      # Ace editor updates a hidden textarea and it happens asynchronously
      # `sleep 0.1` is actually needed here because of this
      execute_script("ace.edit('ci-editor').setValue(" + yaml_content.to_json + ");")
      sleep 0.1
      click_on 'Validate'
    end

    context 'YAML is correct' do
      let(:yaml_content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      end

      it 'parses Yaml' do
        within "table" do
          expect(page).to have_content('Job - rspec')
          expect(page).to have_content('Job - spinach')
          expect(page).to have_content('Deploy Job - staging')
          expect(page).to have_content('Deploy Job - production')
        end
      end
    end

    context 'YAML is incorrect' do
      let(:yaml_content) { '' }

      it 'displays information about an error' do
        expect(page).to have_content('Status: syntax is incorrect')
        expect(page).to have_content('Error: Please provide content of .gitlab-ci.yml')
      end
    end

    describe 'YAML revalidate' do
      let(:yaml_content) { 'my yaml content' }

      it 'loads previous YAML content after validation' do
        expect(page).to have_field('content', with: 'my yaml content', visible: false, type: 'textarea')
      end
    end
  end
end
