import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import GfmAutoComplete from '~/gfm_auto_complete';
import { TYPE_ISSUE } from '~/issues/constants';
import RelatedIssuableInput from '~/related_issues/components/related_issuable_input.vue';
import { PathIdSeparator } from '~/related_issues/constants';

jest.mock('~/gfm_auto_complete');

describe('RelatedIssuableInput', () => {
  let wrapper;

  const autoCompleteSources = {
    issues: `${TEST_HOST}/h5bp/html5-boilerplate/-/autocomplete_sources/issues`,
  };

  const mountComponent = (props = {}) => {
    wrapper = shallowMount(RelatedIssuableInput, {
      propsData: {
        inputValue: '',
        references: [],
        pathIdSeparator: PathIdSeparator.Issue,
        issuableType: TYPE_ISSUE,
        autoCompleteSources,
        ...props,
      },
      attachTo: document.body,
    });
  };

  describe('autocomplete', () => {
    describe('with autoCompleteSources', () => {
      it('shows placeholder text', () => {
        mountComponent();

        expect(wrapper.findComponent({ ref: 'input' }).element.placeholder).toBe(
          'Paste issue link or <#issue id>',
        );
      });

      it('has GfmAutoComplete', () => {
        mountComponent();

        expect(GfmAutoComplete).toHaveBeenCalledWith(autoCompleteSources);
      });
    });

    describe('with no autoCompleteSources', () => {
      it('shows placeholder text', () => {
        mountComponent({ references: ['!1', '!2'] });

        expect(wrapper.findComponent({ ref: 'input' }).element.value).toBe('');
      });

      it('does not have GfmAutoComplete', () => {
        mountComponent({ autoCompleteSources: {} });

        expect(GfmAutoComplete).not.toHaveBeenCalled();
      });
    });
  });

  describe('focus', () => {
    it('when clicking anywhere on the input wrapper it should focus the input', async () => {
      mountComponent({ references: ['foo', 'bar'] });

      await wrapper.find('li').trigger('click');

      expect(document.activeElement).toBe(wrapper.findComponent({ ref: 'input' }).element);
    });
  });

  describe('when filling in the input', () => {
    it('emits addIssuableFormInput with data', () => {
      mountComponent();

      const newInputValue = 'filling in things';
      const untouchedRawReferences = newInputValue.trim().split(/\s/);
      const touchedReference = untouchedRawReferences.pop();
      const input = wrapper.findComponent({ ref: 'input' });

      input.element.value = newInputValue;
      input.element.selectionStart = newInputValue.length;
      input.element.selectionEnd = newInputValue.length;
      input.trigger('input');

      expect(wrapper.emitted('addIssuableFormInput')).toEqual([
        [
          {
            newValue: newInputValue,
            caretPos: newInputValue.length,
            untouchedRawReferences,
            touchedReference,
          },
        ],
      ]);
    });
  });
});
