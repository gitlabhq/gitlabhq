# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::BreadcrumbComponent, type: :component, feature_category: :design_system do
  it 'uses the correct class on the root element' do
    render_inline described_class.new
    expect(page).to have_selector('.gl-breadcrumbs')
  end

  it 'adds the required classes to the list element' do
    render_inline described_class.new
    expect(page).to have_selector('.gl-breadcrumb-list.breadcrumb.js-breadcrumbs-list')
  end

  it 'applies any provided HTML attribute to the root element' do
    render_inline described_class.new(class: 'myClass', data: { foo: 'bar' }, id: 'myID')
    expect(page).to have_selector('.gl-breadcrumbs.myClass#myID[data-foo="bar"]')
  end

  it 'renders one GlBreadcrumbItem per item slot' do
    render_inline described_class.new do |c|
      c.with_item(text: 'First', href: '/')
      c.with_item(text: 'Second', href: '#')
    end

    expect(page).to have_selector('.gl-breadcrumb-item', count: 2)
    expect(page).to have_content('First')
    expect(page).to have_content('Second')
  end
end
