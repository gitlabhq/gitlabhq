import { GlForm, GlFormInput, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import BoardNewItem from '~/boards/components/board_new_item.vue';
import eventHub from '~/boards/eventhub';

import { mockList } from '../mock_data';

const createComponent = ({
  list = mockList,
  formEventPrefix = 'toggle-issue-form-',
  disabledSubmit = false,
  submitButtonTitle = 'Create item',
} = {}) =>
  mountExtended(BoardNewItem, {
    propsData: {
      list,
      formEventPrefix,
      disabledSubmit,
      submitButtonTitle,
    },
    slots: {
      default: '<div id="default-slot"></div>',
    },
    stubs: {
      GlForm,
    },
  });

describe('BoardNewItem', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders gl-form component', () => {
      expect(wrapper.findComponent(GlForm).exists()).toBe(true);
    });

    it('renders field label', () => {
      expect(wrapper.find('label').exists()).toBe(true);
      expect(wrapper.find('label').text()).toBe('Title');
    });

    it('renders gl-form-input field', () => {
      expect(wrapper.findComponent(GlFormInput).exists()).toBe(true);
    });

    it('renders default slot contents', () => {
      expect(wrapper.find('#default-slot').exists()).toBe(true);
    });

    it('renders submit and cancel buttons', () => {
      const buttons = wrapper.findAllComponents(GlButton);
      expect(buttons).toHaveLength(2);
      expect(buttons.at(0).text()).toBe('Create item');
      expect(buttons.at(1).text()).toBe('Cancel');
    });

    describe('events', () => {
      const glForm = () => wrapper.findComponent(GlForm);
      const titleInput = () => wrapper.find('input[name="issue_title"]');

      it('emits `form-submit` event with title value when `submit` is triggered on gl-form', async () => {
        titleInput().setValue('Foo');
        await glForm().trigger('submit');

        expect(wrapper.emitted('form-submit')).toBeTruthy();
        expect(wrapper.emitted('form-submit')[0]).toEqual([
          {
            title: 'Foo',
            list: mockList,
          },
        ]);
      });

      it('emits `scroll-board-list-` event with list.id on eventHub when `submit` is triggered on gl-form', async () => {
        jest.spyOn(eventHub, '$emit').mockImplementation();
        await glForm().trigger('submit');

        expect(eventHub.$emit).toHaveBeenCalledWith(`scroll-board-list-${mockList.id}`);
      });

      it('emits `form-cancel` event and clears title value when `reset` is triggered on gl-form', async () => {
        titleInput().setValue('Foo');

        await wrapper.vm.$nextTick();
        expect(titleInput().element.value).toBe('Foo');

        await glForm().trigger('reset');

        expect(titleInput().element.value).toBe('');
        expect(wrapper.emitted('form-cancel')).toBeTruthy();
      });
    });
  });
});
