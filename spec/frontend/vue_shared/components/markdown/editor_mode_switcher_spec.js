import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';

describe('vue_shared/component/markdown/editor_mode_switcher', () => {
  let wrapper;

  const createComponent = ({ value } = {}) => {
    wrapper = shallowMount(EditorModeSwitcher, {
      propsData: {
        value,
      },
    });
  };

  const findSwitcherButton = () => wrapper.findComponent(GlButton);

  describe.each`
    modeText       | value         | buttonText
    ${'Rich text'} | ${'richText'} | ${'Switch to Markdown'}
    ${'Markdown'}  | ${'markdown'} | ${'Switch to rich text'}
  `('when $modeText', ({ modeText, value, buttonText }) => {
    beforeEach(() => {
      createComponent({ value });
    });

    it('shows correct button label', () => {
      expect(findSwitcherButton().text()).toEqual(buttonText);
    });

    it('emits event on click', () => {
      findSwitcherButton(modeText).vm.$emit('click');

      expect(wrapper.emitted().input).toEqual([[]]);
    });
  });
});
