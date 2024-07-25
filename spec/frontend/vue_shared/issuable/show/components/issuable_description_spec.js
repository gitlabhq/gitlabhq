import { shallowMount } from '@vue/test-utils';

import IssuableDescription from '~/vue_shared/issuable/show/components/issuable_description.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

import { mockIssuable } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

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
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  describe('mounted', () => {
    it('calls `renderGFM`', () => {
      expect(renderGFM).toHaveBeenCalledTimes(1);
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
      const textareaEl = wrapper.find('textarea.gl-hidden.js-task-list-field');

      expect(textareaEl.exists()).toBe(true);
      expect(textareaEl.attributes('data-update-url')).toBe(`${mockIssuable.webUrl}.json`);
    });
  });
});
