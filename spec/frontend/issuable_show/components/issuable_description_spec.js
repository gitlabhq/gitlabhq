import { shallowMount } from '@vue/test-utils';
import $ from 'jquery';

import IssuableDescription from '~/issuable_show/components/issuable_description.vue';

import { mockIssuable } from '../mock_data';

const createComponent = ({
  issuable = mockIssuable,
  enableTaskList = true,
  canEdit = true,
  taskListUpdatePath = `${mockIssuable.webUrl}.json`,
} = {}) =>
  shallowMount(IssuableDescription, {
    propsData: { issuable, enableTaskList, canEdit, taskListUpdatePath },
  });

describe('IssuableDescription', () => {
  let renderGFMSpy;
  let wrapper;

  beforeEach(() => {
    renderGFMSpy = jest.spyOn($.fn, 'renderGFM');
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('mounted', () => {
    it('calls `renderGFM`', () => {
      expect(renderGFMSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('methods', () => {
    describe('renderGFM', () => {
      it('calls `renderGFM` on container element', () => {
        wrapper.vm.renderGFM();

        expect(renderGFMSpy).toHaveBeenCalled();
      });
    });
  });

  describe('templates', () => {
    it('renders container element with class `js-task-list-container` when canEdit and enableTaskList props are true', () => {
      expect(wrapper.classes()).toContain('js-task-list-container');
    });

    it('renders container element without class `js-task-list-container` when canEdit and enableTaskList props are true', () => {
      const wrapperNoTaskList = createComponent({
        enableTaskList: false,
      });

      expect(wrapperNoTaskList.classes()).not.toContain('js-task-list-container');

      wrapperNoTaskList.destroy();
    });

    it('renders hidden textarea element when issuable.description is present and enableTaskList prop is true', () => {
      const textareaEl = wrapper.find('textarea.gl-display-none.js-task-list-field');

      expect(textareaEl.exists()).toBe(true);
      expect(textareaEl.attributes('data-update-url')).toBe(`${mockIssuable.webUrl}.json`);
    });
  });
});
