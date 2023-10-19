import { nextTick } from 'vue';
import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('vue_shared/component/markdown/editor_mode_switcher', () => {
  let wrapper;
  useLocalStorageSpy();

  const createComponent = ({ value } = {}) => {
    wrapper = mount(EditorModeSwitcher, {
      propsData: {
        value,
      },
    });
  };

  const findSwitcherButton = () => wrapper.findComponent(GlButton);

  describe.each`
    value         | buttonText
    ${'richText'} | ${'Switch to plain text editing'}
    ${'markdown'} | ${'Switch to rich text editing'}
  `('when $value', ({ value, buttonText }) => {
    beforeEach(() => {
      createComponent({ value });
    });

    it('shows correct button label', () => {
      expect(findSwitcherButton().text()).toEqual(buttonText);
    });

    it('emits event on click', async () => {
      await nextTick();
      findSwitcherButton().vm.$emit('click');

      expect(wrapper.emitted().switch).toEqual([[]]);
    });
  });
});
