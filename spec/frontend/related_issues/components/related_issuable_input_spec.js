import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import RelatedIssuableInput from '~/related_issues/components/related_issuable_input.vue';
import { issuableTypesMap, PathIdSeparator } from '~/related_issues/constants';

jest.mock('ee_else_ce/gfm_auto_complete', () => {
  return function gfmAutoComplete() {
    return {
      constructor() {},
      setup() {},
    };
  };
});

describe('RelatedIssuableInput', () => {
  let propsData;

  beforeEach(() => {
    propsData = {
      inputValue: '',
      references: [],
      pathIdSeparator: PathIdSeparator.Issue,
      issuableType: issuableTypesMap.issue,
      autoCompleteSources: {
        issues: `${TEST_HOST}/h5bp/html5-boilerplate/-/autocomplete_sources/issues`,
      },
    };
  });

  describe('autocomplete', () => {
    describe('with autoCompleteSources', () => {
      it('shows placeholder text', () => {
        const wrapper = shallowMount(RelatedIssuableInput, { propsData });

        expect(wrapper.find({ ref: 'input' }).element.placeholder).toBe(
          'Paste issue link or <#issue id>',
        );
      });

      it('has GfmAutoComplete', () => {
        const wrapper = shallowMount(RelatedIssuableInput, { propsData });

        expect(wrapper.vm.gfmAutoComplete).toBeDefined();
      });
    });

    describe('with no autoCompleteSources', () => {
      it('shows placeholder text', () => {
        const wrapper = shallowMount(RelatedIssuableInput, {
          propsData: {
            ...propsData,
            references: ['!1', '!2'],
          },
        });

        expect(wrapper.find({ ref: 'input' }).element.value).toBe('');
      });

      it('does not have GfmAutoComplete', () => {
        const wrapper = shallowMount(RelatedIssuableInput, {
          propsData: {
            ...propsData,
            autoCompleteSources: {},
          },
        });

        expect(wrapper.vm.gfmAutoComplete).not.toBeDefined();
      });
    });
  });

  describe('focus', () => {
    it('when clicking anywhere on the input wrapper it should focus the input', async () => {
      const wrapper = shallowMount(RelatedIssuableInput, {
        propsData: {
          ...propsData,
          references: ['foo', 'bar'],
        },
        // We need to attach to document, so that `document.activeElement` is properly set in jsdom
        attachTo: document.body,
      });

      wrapper.find('li').trigger('click');

      await wrapper.vm.$nextTick();

      expect(document.activeElement).toBe(wrapper.find({ ref: 'input' }).element);
    });
  });

  describe('when filling in the input', () => {
    it('emits addIssuableFormInput with data', () => {
      const wrapper = shallowMount(RelatedIssuableInput, {
        propsData,
      });

      wrapper.vm.$emit = jest.fn();

      const newInputValue = 'filling in things';
      const untouchedRawReferences = newInputValue.trim().split(/\s/);
      const touchedReference = untouchedRawReferences.pop();
      const input = wrapper.find({ ref: 'input' });

      input.element.value = newInputValue;
      input.element.selectionStart = newInputValue.length;
      input.element.selectionEnd = newInputValue.length;
      input.trigger('input');

      expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormInput', {
        newValue: newInputValue,
        caretPos: newInputValue.length,
        untouchedRawReferences,
        touchedReference,
      });
    });
  });
});
