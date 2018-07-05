require 'spec_helper'

describe 'Environment > Pod Logs', :js do
  include KubernetesHelpers

  let(:pod_names) { %w(foo bar) }
  let(:pod_name) { pod_names.first }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, project: project) }

  before do
    stub_licensed_features(pod_logs: true)

    create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project])
    create(:deployment, environment: environment)

    allow_any_instance_of(EE::KubernetesService).to receive(:read_pod_logs).with(pod_name).and_return(kube_logs_body)
    allow_any_instance_of(EE::Environment).to receive(:pod_names).and_return(pod_names)

    sign_in(project.owner)
  end

  context 'with logs' do
    it "shows pod logs" do
      visit logs_project_environment_path(environment.project, environment, pod_name: pod_name)

      wait_for_requests

      page.within('.js-pod-dropdown') do
        find(".dropdown-menu-toggle").click

        dropdown_items = find(".dropdown-menu").all(".dropdown-item")
        expect(dropdown_items.size).to eq(2)

        dropdown_items.each_with_index do |item, i|
          expect(item.text).to eq(pod_names[i])
        end
      end
      expect(page).to have_content("Log 1\nLog 2\nLog 3")
    end
  end
end
