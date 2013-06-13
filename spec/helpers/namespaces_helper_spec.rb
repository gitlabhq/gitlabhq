require "spec_helper"

describe NamespacesHelper do
  describe "normal user" do
    let(:current_user) { create :user }

    it { namespaces_options.should match /Users/ }
    it { namespaces_options.should match /Groups/ }
    it { namespaces_options.should_not match /Global/ }
  end

  describe "global project creatable user" do
    let(:current_user) { create :user, can_create_global_project: true }

    it { namespaces_options.should match /Users/ }
    it { namespaces_options.should match /Groups/ }
    it { namespaces_options.should match /Global/ }
  end
end

