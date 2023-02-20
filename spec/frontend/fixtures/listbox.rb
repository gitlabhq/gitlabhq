# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'initRedirectListboxBehavior', '(JavaScript fixtures)', type: :helper do
  include JavaScriptFixturesHelpers
  include ListboxHelper

  let(:response) { @tag }

  it 'listbox/redirect_listbox.html' do
    items = [{
      value: 'foo',
      text: 'Foo',
      href: '/foo',
      arbitrary_key: 'foo xyz'
    }, {
      value: 'bar',
      text: 'Bar',
      href: '/bar',
      arbitrary_key: 'bar xyz'
    }, {
      value: 'qux',
      text: 'Qux',
      href: '/qux',
      arbitrary_key: 'qux xyz'
    }]

    @tag = helper.gl_redirect_listbox_tag(items, 'bar',
      class: %w[test-class-1 test-class-2],
      data: { placement: 'right' }
    )
  end
end
