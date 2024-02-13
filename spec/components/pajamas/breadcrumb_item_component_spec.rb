# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::BreadcrumbItemComponent, type: :component, feature_category: :design_system do
  before do
    render_inline described_class.new(text: 'Foo', href: '/bar')
  end

  subject { page }

  it { is_expected.to have_selector('.gl-breadcrumb-item a') }
  it { is_expected.to have_link('Foo', href: '/bar') }
end
