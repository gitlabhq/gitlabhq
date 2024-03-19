import { GlForm, GlFormInput, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import BoardNewItem from '~/boards/components/board_new_item.vue';

import { mockList } from '../mock_data';

const createComponent = ({
  list = mockList,
  disabledSubmit = false,
  submitButtonTitle = 'Create item',
} = {}) =>
  mountExtended(BoardNewItem, {
    propsData: {
      list,
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

  describe('template', () => {
    describe('when the user provides a valid input', () => {
      it('finds an enabled create button', async () => {
        expect(wrapper.findByTestId('create-button').props('disabled')).toBe(true);

        wrapper.findComponent(GlFormInput).vm.$emit('input', 'hello');
        await nextTick();

        expect(wrapper.findByTestId('create-button').props('disabled')).toBe(false);
      });
    });

    describe('when the user types in a string with only spaces', () => {
      it('disables the Create Issue button', async () => {
        wrapper.findComponent(GlFormInput).vm.$emit('input', '    ');

        await nextTick();

        expect(wrapper.findByTestId('create-button').props('disabled')).toBe(true);
      });
    });

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

        expect(wrapper.emitted('form-submit')).toHaveLength(1);
        expect(wrapper.emitted('form-submit')[0]).toEqual([
          {
            title: 'Foo',
            list: mockList,
          },
        ]);
      });

      it('emits `form-submit` event with trimmed title', async () => {
        titleInput().setValue(' Foo   ');

        await glForm().trigger('submit');

        expect(wrapper.emitted('form-submit')[0]).toEqual([
          {
            title: 'Foo',
            list: mockList,
          },
        ]);
      });

      it('emits `form-cancel` event and clears title value when `reset` is triggered on gl-form', async () => {
        titleInput().setValue('Foo');

        await nextTick();
        expect(titleInput().element.value).toBe('Foo');

        await glForm().trigger('reset');

        expect(titleInput().element.value).toBe('');
        expect(wrapper.emitted('form-cancel')).toHaveLength(1);
      });
    });
  });
});
