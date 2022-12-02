# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GlTabsBehavior', '(JavaScript fixtures)', type: :helper do
  include JavaScriptFixturesHelpers
  include TabHelper

  let(:response) { @tabs }

  it 'tabs/tabs.html' do
    tabs = gl_tabs_nav({ data: { testid: 'tabs' } }) do
      gl_tab_link_to('Foo', '#foo', item_active: true, data: { testid: 'foo-tab' }) +
        gl_tab_link_to('Bar', '#bar', item_active: false, data: { testid: 'bar-tab' }) +
        gl_tab_link_to('Qux', '#qux', item_active: false, data: { testid: 'qux-tab' })
    end

    panels = content_tag(:div, class: 'tab-content') do
      content_tag(:div, 'Foo', { id: 'foo', class: 'tab-pane active', data: { testid: 'foo-panel' } }) +
        content_tag(:div, 'Bar', { id: 'bar', class: 'tab-pane', data: { testid: 'bar-panel' } }) +
        content_tag(:div, 'Qux', { id: 'qux', class: 'tab-pane', data: { testid: 'qux-panel' } })
    end

    @tabs = tabs + panels
  end
end
