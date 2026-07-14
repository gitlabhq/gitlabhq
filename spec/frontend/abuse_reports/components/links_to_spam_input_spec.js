import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import LinksToSpamInput from '~/abuse_reports/components/links_to_spam_input.vue';

describe('LinksToSpamInput', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMountExtended(LinksToSpamInput, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findAllFormGroups = () => wrapper.findAllComponents(GlFormGroup);
  const findLinkInput = () => wrapper.findComponent(GlFormInput);
  const findAllLinkInputs = () => wrapper.findAllComponents(GlFormInput);
  const findAddAnotherButton = () =>
    wrapper.findAllComponents(GlButton).wrappers.find((b) => b.props('icon') === 'plus');
  const findRemoveButtons = () =>
    wrapper.findAllComponents(GlButton).wrappers.filter((b) => b.props('icon') === 'remove');

  describe('Form Input', () => {
    it('renders only one input field initially', () => {
      expect(findAllFormGroups()).toHaveLength(1);
    });

    it('is of type URL and has a name attribute', () => {
      expect(findLinkInput().attributes()).toMatchObject({
        type: 'url',
        name: 'abuse_report[links_to_spam][]',
        value: '',
      });
    });

    it('does not render a remove button on the first input', () => {
      expect(findRemoveButtons()).toHaveLength(0);
    });

    describe('when add another link button is clicked', () => {
      beforeEach(async () => {
        findAddAnotherButton().vm.$emit('click');
        await nextTick();
      });

      it('adds another input', () => {
        expect(findAllFormGroups()).toHaveLength(2);
      });

      it('renders a remove button only on the added input', () => {
        const removeButtons = findRemoveButtons();
        expect(removeButtons).toHaveLength(1);
        expect(removeButtons[0].attributes('aria-label')).toBe('Remove link');
      });

      describe('when the remove button is clicked', () => {
        it('removes that input and leaves only the first', async () => {
          findRemoveButtons()[0].vm.$emit('click');
          await nextTick();

          expect(findAllFormGroups()).toHaveLength(1);
          expect(findRemoveButtons()).toHaveLength(0);
        });

        it('removes the correct entry from the submitted payload', async () => {
          createComponent({
            previousLinks: ['https://a.test', 'https://b.test', 'https://c.test'],
          });

          findRemoveButtons()[0].vm.$emit('click');
          await nextTick();

          const values = findAllLinkInputs().wrappers.map((w) => w.attributes('value'));
          expect(values).toEqual(['https://a.test', 'https://c.test']);
        });
      });
    });

    describe('when previously added links are passed to the form as props', () => {
      beforeEach(() => {
        createComponent({ previousLinks: ['https://gitlab.com'] });
      });

      it('renders the input field with the value of the link pre-filled', () => {
        expect(findAllFormGroups()).toHaveLength(1);

        expect(findLinkInput().attributes()).toMatchObject({
          type: 'url',
          name: 'abuse_report[links_to_spam][]',
          value: 'https://gitlab.com',
        });
      });
    });
  });
});
