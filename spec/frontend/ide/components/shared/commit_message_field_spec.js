import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CommitMessageField from '~/ide/components/shared/commit_message_field.vue';

const DEFAULT_PROPS = {
  text: 'foo text',
  placeholder: 'foo placeholder',
};

describe('CommitMessageField', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CommitMessageField, {
        propsData: {
          ...DEFAULT_PROPS,
          ...props,
        },
        attachTo: document.body,
      }),
    );
  };

  const findTextArea = () => wrapper.find('textarea');
  const findHighlights = () => wrapper.findByTestId('highlights');
  const findHighlightsText = () => wrapper.findByTestId('highlights-text');
  const findHighlightsMark = () => wrapper.findByTestId('highlights-mark');
  const findHighlightsTexts = () => wrapper.findAllByTestId('highlights-text');
  const findHighlightsMarks = () => wrapper.findAllByTestId('highlights-mark');

  const fillText = async (text) => {
    wrapper.setProps({ text });
    await nextTick();
  };

  it('emits input event on input', () => {
    const value = 'foo';

    createComponent();
    findTextArea().setValue(value);
    expect(wrapper.emitted('input')[0][0]).toEqual(value);
  });

  describe('focus classes', () => {
    beforeEach(async () => {
      createComponent();
      findTextArea().trigger('focus');
      await nextTick();
    });

    it('is added on textarea focus', () => {
      expect(wrapper.attributes('class')).toEqual(
        expect.stringContaining('gl-outline-none! gl-focus-ring-border-1-gray-900!'),
      );
    });

    it('is removed on textarea blur', async () => {
      findTextArea().trigger('blur');
      await nextTick();

      expect(wrapper.attributes('class')).toEqual(
        expect.not.stringContaining('gl-outline-none! gl-focus-ring-border-1-gray-900!'),
      );
    });
  });

  describe('highlights', () => {
    describe('subject line', () => {
      it('does not highlight less than 50 characters', async () => {
        const text = 'text less than 50 chars';

        createComponent();
        await fillText(text);

        expect(findHighlightsText().text()).toEqual(text);
        expect(findHighlightsMark().text()).toBe('');
      });

      it('highlights characters over 50 length', async () => {
        const text =
          'text less than 50 chars that should not highlighted. text more than 50 should be highlighted';

        createComponent();
        await fillText(text);

        expect(findHighlightsText().text()).toEqual(text.slice(0, 50));
        expect(findHighlightsMark().text()).toEqual(text.slice(50));
      });
    });

    describe('body text', () => {
      it('does not highlight body text less tan 72 characters', async () => {
        const text = 'subject line\nbody content';

        createComponent();
        await fillText(text);

        expect(findHighlightsTexts()).toHaveLength(2);
        expect(findHighlightsMarks().at(1).attributes('style')).toEqual('display: none;');
      });

      it('highlights body text more than 72 characters', async () => {
        const text =
          'subject line\nbody content that will be highlighted when it is more than 72 characters in length';

        createComponent();
        await fillText(text);

        expect(findHighlightsTexts()).toHaveLength(2);
        expect(findHighlightsMarks().at(1).attributes('style')).not.toEqual('display: none;');
        expect(findHighlightsMarks().at(1).element.textContent).toEqual(' in length');
      });

      it('highlights body text & subject line', async () => {
        const text =
          'text less than 50 chars that should not highlighted\nbody content that will be highlighted when it is more than 72 characters in length';

        createComponent();
        await fillText(text);

        expect(findHighlightsTexts()).toHaveLength(2);
        expect(findHighlightsMarks()).toHaveLength(2);
        expect(findHighlightsMarks().at(0).element.textContent).toEqual('d');
        expect(findHighlightsMarks().at(1).element.textContent).toEqual(' in length');
      });
    });
  });

  describe('scrolling textarea', () => {
    it('updates transform of highlights', async () => {
      const yCoord = 50;

      createComponent();
      await fillText('subject line\n\n\n\n\n\n\n\n\n\n\nbody content');

      wrapper.vm.$el.querySelector('textarea').scrollTo(0, yCoord);
      await nextTick();

      expect(wrapper.vm.scrollTop).toEqual(yCoord);
      expect(findHighlights().attributes('style')).toEqual('transform: translate3d(0, -50px, 0);');
    });
  });
});
