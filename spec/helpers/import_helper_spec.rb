require 'rails_helper'

describe ImportHelper do
  describe '#github_project_link' do
    context 'when provider does not specify a custom URL' do
      it 'uses default GitHub URL' do
        allow(Gitlab.config.omniauth).to receive(:providers).
          and_return([Settingslogic.new('name' => 'github')])

        expect(helper.github_project_link('octocat/Hello-World')).
          to include('href="https://github.com/octocat/Hello-World"')
      end
    end

    context 'when provider specify a custom URL' do
      it 'uses custom URL' do
        allow(Gitlab.config.omniauth).to receive(:providers).
          and_return([Settingslogic.new('name' => 'github', 'url' => 'https://github.company.com')])

        expect(helper.github_project_link('octocat/Hello-World')).
          to include('href="https://github.company.com/octocat/Hello-World"')
      end
    end
  end
end
