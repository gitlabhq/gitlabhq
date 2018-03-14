require 'spec_helper'

describe 'CI Lint', :js do
  before do
    sign_in(create(:user))

    visit ci_lint_path
    find('#ci-editor')
    execute_script("ace.edit('ci-editor').setValue(#{yaml_content.to_json});")

    # Ace editor updates a hidden textarea and it happens asynchronously
    wait_for('YAML content') do
      find('.ace_content').text.present?
    end
  end

  describe 'YAML parsing' do
    before do
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
      let(:yaml_content) { 'value: cannot have :' }

      it 'displays information about an error' do
        expect(page).to have_content('Status: syntax is incorrect')
        expect(page).to have_selector('.ace_content', text: yaml_content)
      end
    end

    describe 'YAML revalidate' do
      let(:yaml_content) { 'my yaml content' }

      it 'loads previous YAML content after validation' do
        expect(page).to have_field('content', with: 'my yaml content', visible: false, type: 'textarea')
      end
    end
  end

  describe 'YAML clearing' do
    before do
      click_on 'Clear'
    end

    context 'YAML is present' do
      let(:yaml_content) do
        File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      end

      it 'YAML content is cleared' do
        expect(page).to have_field('content', with: '', visible: false, type: 'textarea')
      end
    end
  end
end
