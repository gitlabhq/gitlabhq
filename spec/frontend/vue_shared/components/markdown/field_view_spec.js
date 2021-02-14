import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';

import MarkdownFieldView from '~/vue_shared/components/markdown/field_view.vue';

describe('Markdown Field View component', () => {
  let renderGFMSpy;
  let wrapper;

  function createComponent() {
    wrapper = shallowMount(MarkdownFieldView);
  }

  beforeEach(() => {
    renderGFMSpy = jest.spyOn($.fn, 'renderGFM');
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('processes rendering with GFM', () => {
    expect(renderGFMSpy).toHaveBeenCalledTimes(1);
  });
});
