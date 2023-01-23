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
  const findAddAnotherButton = () => wrapper.findComponent(GlButton);

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

    describe('when add another link button is clicked', () => {
      it('adds another input', async () => {
        findAddAnotherButton().vm.$emit('click');

        await nextTick();

        expect(findAllFormGroups()).toHaveLength(2);
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
