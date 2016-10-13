require 'spec_helper'

describe Projects::GraphsController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.team << [user, :master]
  end

  describe 'GET #languages' do
    let(:linguist_repository) do
      double(languages: {
                       'Ruby'         => 1000,
                       'CoffeeScript' => 350,
                       'PowerShell'   => 15
                     })
    end

    let(:expected_values) do
      ps_color = "##{Digest::SHA256.hexdigest('PowerShell')[0...6]}"
      [
        # colors from Linguist:
        { label: "Ruby",         color: "#701516", highlight: "#701516" },
        { label: "CoffeeScript", color: "#244776", highlight: "#244776" },
        # colors from SHA256 fallback:
        { label: "PowerShell",   color: ps_color,  highlight: ps_color  }
      ]
    end

    before do
      allow(Linguist::Repository).to receive(:new).and_return(linguist_repository)
    end

    it 'sets the correct colour according to language' do
      get(:languages, namespace_id: project.namespace.path, project_id: project.path, id: 'master')

      expected_values.each do |val|
        expect(assigns(:languages)).to include(include(val))
      end
    end
  end
end
