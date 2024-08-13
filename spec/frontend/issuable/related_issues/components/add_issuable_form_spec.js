import { GlButton, GlFormGroup, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import AddIssuableForm from '~/related_issues/components/add_issuable_form.vue';
import IssueToken from '~/related_issues/components/issue_token.vue';
import RelatedIssuableInput from '~/related_issues/components/related_issuable_input.vue';
import { linkedIssueTypesMap, PathIdSeparator } from '~/related_issues/constants';

const issuable1 = {
  id: 200,
  reference: 'foo/bar#123',
  displayReference: '#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
};

const issuable2 = {
  id: 201,
  reference: 'foo/bar#124',
  displayReference: '#124',
  title: 'some other thing',
  path: '/foo/bar/issues/124',
  state: 'opened',
};

const pathIdSeparator = PathIdSeparator.Issue;

describe('AddIssuableForm', () => {
  let wrapper;

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(AddIssuableForm, {
      propsData: {
        inputValue: '',
        pendingReferences: [],
        pathIdSeparator,
        ...props,
      },
      stubs: {
        RelatedIssuableInput,
      },
    });
  };

  const findAddIssuableForm = () => wrapper.find('form');
  const findFormInput = () => wrapper.find('input').element;
  const findRadioInput = (inputs, value) =>
    inputs.filter((input) => input.element.value === value)[0];
  const findAllIssueTokens = () => wrapper.findAllComponents(IssueToken);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findRadioInputs = () => wrapper.findAllComponents(GlFormRadio);

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findFormButtons = () => wrapper.findAllComponents(GlButton);
  const findSubmitButton = () => findFormButtons().at(0);
  const findRelatedIssuableInput = () => wrapper.findComponent(RelatedIssuableInput);

  describe('with data', () => {
    describe('without references', () => {
      describe('without any input text', () => {
        beforeEach(() => {
          createComponent();
        });

        it('should have disabled submit button', () => {
          expect(findSubmitButton().props('disabled')).toBe(true);
          expect(findSubmitButton().props('loading')).toBe(false);
        });
      });

      describe('with input text', () => {
        beforeEach(() => {
          createComponent({
            inputValue: 'foo',
            pendingReferences: [],
            pathIdSeparator,
          });
        });

        it('should not have disabled submit button', () => {
          expect(findSubmitButton().props('disabled')).toBe(false);
        });
      });
    });

    describe('with references', () => {
      const inputValue = 'foo #123';

      beforeEach(() => {
        createComponent({
          inputValue,
          pendingReferences: [issuable1.reference, issuable2.reference],
          pathIdSeparator,
        });
      }, mount);

      it('should put input value in place', () => {
        expect(findFormInput(wrapper).value).toBe(inputValue);
      });

      it('should render pending issuables items', () => {
        expect(findAllIssueTokens()).toHaveLength(2);
      });

      it('should not have disabled submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });
    });

    describe('when issuable type is "issue"', () => {
      beforeEach(() => {
        createComponent(
          {
            inputValue: '',
            issuableType: TYPE_ISSUE,
            pathIdSeparator,
            pendingReferences: [],
          },
          mount,
        );
      });

      it('does not show radio inputs', () => {
        expect(findRadioInputs()).toHaveLength(0);
      });
    });

    describe('when issuable type is "epic"', () => {
      beforeEach(() => {
        createComponent({
          inputValue: '',
          issuableType: TYPE_EPIC,
          pathIdSeparator,
          pendingReferences: [],
        });
      });

      it('does not show radio inputs', () => {
        expect(findRadioInputs()).toHaveLength(0);
      });
    });

    describe('categorized issuables', () => {
      it.each`
        issuableType  | pathIdSeparator          | contextHeader          | contextFooter
        ${TYPE_ISSUE} | ${PathIdSeparator.Issue} | ${'The current issue'} | ${'the following issues'}
        ${TYPE_EPIC}  | ${PathIdSeparator.Epic}  | ${'The current epic'}  | ${'the following epics'}
      `(
        'show header text as "$contextHeader" and footer text as "$contextFooter" issuableType is set to $issuableType',
        ({ issuableType, contextHeader, contextFooter }) => {
          createComponent({
            issuableType,
            inputValue: '',
            showCategorizedIssues: true,
            pathIdSeparator,
            pendingReferences: [],
          });

          expect(findFormGroup().attributes('label')).toBe(contextHeader);
          expect(wrapper.text()).toContain(contextFooter);
        },
      );
    });

    describe('when it is a Linked Issues form', () => {
      beforeEach(() => {
        createComponent({
          inputValue: '',
          showCategorizedIssues: true,
          issuableType: TYPE_ISSUE,
          pathIdSeparator,
          pendingReferences: [],
        });
      });

      it('shows radio inputs to allow categorisation of blocking issues', () => {
        expect(findRadioGroup().props('options').length).toBeGreaterThan(0);
      });

      describe('form radio buttons', () => {
        let radioInputs;

        beforeEach(() => {
          radioInputs = findRadioInputs();
        });

        it('shows "relates to" option', () => {
          expect(findRadioInput(radioInputs, linkedIssueTypesMap.RELATES_TO)).not.toBeNull();
        });

        it('shows "blocks" option', () => {
          expect(findRadioInput(radioInputs, linkedIssueTypesMap.BLOCKS)).not.toBeNull();
        });

        it('shows "is blocked by" option', () => {
          expect(findRadioInput(radioInputs, linkedIssueTypesMap.IS_BLOCKED_BY)).not.toBeNull();
        });

        it('shows 3 options in total', () => {
          expect(findRadioGroup().props('options')).toHaveLength(3);
        });
      });

      describe('when the form is submitted', () => {
        it('emits an event with a "relates_to" link type when the "relates to" radio input selected', () => {
          findAddIssuableForm().trigger('submit');

          expect(wrapper.emitted('addIssuableFormSubmit')).toEqual([
            [
              {
                pendingReferences: '',
                linkedIssueType: linkedIssueTypesMap.RELATES_TO,
              },
            ],
          ]);
        });

        it('emits an event with a "blocks" link type when the "blocks" radio input selected', () => {
          findRadioGroup().vm.$emit('input', linkedIssueTypesMap.BLOCKS);
          findAddIssuableForm().trigger('submit');

          expect(wrapper.emitted('addIssuableFormSubmit')).toEqual([
            [
              {
                pendingReferences: '',
                linkedIssueType: linkedIssueTypesMap.BLOCKS,
              },
            ],
          ]);
        });

        it('emits an event with a "is_blocked_by" link type when the "is blocked by" radio input selected', () => {
          findRadioGroup().vm.$emit('input', linkedIssueTypesMap.IS_BLOCKED_BY);
          findAddIssuableForm().trigger('submit');

          expect(wrapper.emitted('addIssuableFormSubmit')).toEqual([
            [
              {
                pendingReferences: '',
                linkedIssueType: linkedIssueTypesMap.IS_BLOCKED_BY,
              },
            ],
          ]);
        });

        it('shows error message when error is present', () => {
          const itemAddFailureMessage = 'Something went wrong while submitting.';
          createComponent({
            hasError: true,
            itemAddFailureMessage,
          });

          expect(wrapper.find('.gl-field-error').exists()).toBe(true);
          expect(wrapper.find('.gl-field-error').text()).toContain(itemAddFailureMessage);
        });
      });
    });
  });

  describe('computed', () => {
    describe('transformedAutocompleteSources', () => {
      const autoCompleteSources = {
        issues: 'http://localhost/autocomplete/issues',
        epics: 'http://localhost/autocomplete/epics',
      };

      it('returns autocomplete object', () => {
        createComponent({
          autoCompleteSources,
        });

        expect(findRelatedIssuableInput().props('autoCompleteSources')).toEqual(
          autoCompleteSources,
        );

        createComponent({
          autoCompleteSources,
          confidential: false,
        });

        expect(findRelatedIssuableInput().props('autoCompleteSources')).toEqual(
          autoCompleteSources,
        );
      });

      it('returns autocomplete sources with query `confidential_only`, when it is confidential', () => {
        createComponent({
          autoCompleteSources,
          confidential: true,
        });

        const actualSources = findRelatedIssuableInput().props('autoCompleteSources');

        expect(actualSources.epics).toContain('?confidential_only=true');
        expect(actualSources.issues).toContain('?confidential_only=true');
      });
    });
  });
});
