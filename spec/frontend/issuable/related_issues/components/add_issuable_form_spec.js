import { mount, shallowMount } from '@vue/test-utils';
import { issuableTypesMap, linkedIssueTypesMap, PathIdSeparator } from '~/related_issues/constants';
import AddIssuableForm from '~/related_issues/components/add_issuable_form.vue';

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

const findFormInput = wrapper => wrapper.find('.js-add-issuable-form-input').element;

const findRadioInput = (inputs, value) => inputs.filter(input => input.element.value === value)[0];

const findRadioInputs = wrapper => wrapper.findAll('[name="linked-issue-type-radio"]');

const constructWrapper = props => {
  return shallowMount(AddIssuableForm, {
    propsData: {
      inputValue: '',
      pendingReferences: [],
      pathIdSeparator,
      ...props,
    },
  });
};

describe('AddIssuableForm', () => {
  let wrapper;

  afterEach(() => {
    // Jest doesn't blur an item even if it is destroyed,
    // so blur the input manually after each test
    const input = findFormInput(wrapper);
    if (input) input.blur();

    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with data', () => {
    describe('without references', () => {
      describe('without any input text', () => {
        beforeEach(() => {
          wrapper = shallowMount(AddIssuableForm, {
            propsData: {
              inputValue: '',
              pendingReferences: [],
              pathIdSeparator,
            },
          });
        });

        it('should have disabled submit button', () => {
          expect(wrapper.vm.$refs.addButton.disabled).toBe(true);
          expect(wrapper.vm.$refs.loadingIcon).toBeUndefined();
        });
      });

      describe('with input text', () => {
        beforeEach(() => {
          wrapper = shallowMount(AddIssuableForm, {
            propsData: {
              inputValue: 'foo',
              pendingReferences: [],
              pathIdSeparator,
            },
          });
        });

        it('should not have disabled submit button', () => {
          expect(wrapper.vm.$refs.addButton.disabled).toBe(false);
        });
      });
    });

    describe('with references', () => {
      const inputValue = 'foo #123';

      beforeEach(() => {
        wrapper = mount(AddIssuableForm, {
          propsData: {
            inputValue,
            pendingReferences: [issuable1.reference, issuable2.reference],
            pathIdSeparator,
          },
        });
      });

      it('should put input value in place', () => {
        expect(findFormInput(wrapper).value).toEqual(inputValue);
      });

      it('should render pending issuables items', () => {
        expect(wrapper.findAll('.js-add-issuable-form-token-list-item').length).toEqual(2);
      });

      it('should not have disabled submit button', () => {
        expect(wrapper.vm.$refs.addButton.disabled).toBe(false);
      });
    });

    describe('when issuable type is "issue"', () => {
      beforeEach(() => {
        wrapper = mount(AddIssuableForm, {
          propsData: {
            inputValue: '',
            issuableType: issuableTypesMap.ISSUE,
            pathIdSeparator,
            pendingReferences: [],
          },
        });
      });

      it('does not show radio inputs', () => {
        expect(findRadioInputs(wrapper).length).toBe(0);
      });
    });

    describe('when issuable type is "epic"', () => {
      beforeEach(() => {
        wrapper = shallowMount(AddIssuableForm, {
          propsData: {
            inputValue: '',
            issuableType: issuableTypesMap.EPIC,
            pathIdSeparator,
            pendingReferences: [],
          },
        });
      });

      it('does not show radio inputs', () => {
        expect(findRadioInputs(wrapper).length).toBe(0);
      });
    });

    describe('when it is a Linked Issues form', () => {
      beforeEach(() => {
        wrapper = mount(AddIssuableForm, {
          propsData: {
            inputValue: '',
            showCategorizedIssues: true,
            issuableType: issuableTypesMap.ISSUE,
            pathIdSeparator,
            pendingReferences: [],
          },
        });
      });

      it('shows radio inputs to allow categorisation of blocking issues', () => {
        expect(findRadioInputs(wrapper).length).toBeGreaterThan(0);
      });

      describe('form radio buttons', () => {
        let radioInputs;

        beforeEach(() => {
          radioInputs = findRadioInputs(wrapper);
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
          expect(radioInputs.length).toBe(3);
        });
      });

      describe('when the form is submitted', () => {
        it('emits an event with a "relates_to" link type when the "relates to" radio input selected', done => {
          jest.spyOn(wrapper.vm, '$emit').mockImplementation(() => {});

          wrapper.vm.linkedIssueType = linkedIssueTypesMap.RELATES_TO;
          wrapper.vm.onFormSubmit();

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', {
              pendingReferences: '',
              linkedIssueType: linkedIssueTypesMap.RELATES_TO,
            });
            done();
          });
        });

        it('emits an event with a "blocks" link type when the "blocks" radio input selected', done => {
          jest.spyOn(wrapper.vm, '$emit').mockImplementation(() => {});

          wrapper.vm.linkedIssueType = linkedIssueTypesMap.BLOCKS;
          wrapper.vm.onFormSubmit();

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', {
              pendingReferences: '',
              linkedIssueType: linkedIssueTypesMap.BLOCKS,
            });
            done();
          });
        });

        it('emits an event with a "is_blocked_by" link type when the "is blocked by" radio input selected', done => {
          jest.spyOn(wrapper.vm, '$emit').mockImplementation(() => {});

          wrapper.vm.linkedIssueType = linkedIssueTypesMap.IS_BLOCKED_BY;
          wrapper.vm.onFormSubmit();

          wrapper.vm.$nextTick(() => {
            expect(wrapper.vm.$emit).toHaveBeenCalledWith('addIssuableFormSubmit', {
              pendingReferences: '',
              linkedIssueType: linkedIssueTypesMap.IS_BLOCKED_BY,
            });
            done();
          });
        });

        it('shows error message when error is present', done => {
          const itemAddFailureMessage = 'Something went wrong while submitting.';
          wrapper.setProps({
            hasError: true,
            itemAddFailureMessage,
          });

          wrapper.vm.$nextTick(() => {
            expect(wrapper.find('.gl-field-error').exists()).toBe(true);
            expect(wrapper.find('.gl-field-error').text()).toContain(itemAddFailureMessage);
            done();
          });
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
        wrapper = constructWrapper({
          autoCompleteSources,
        });

        expect(wrapper.vm.transformedAutocompleteSources).toBe(autoCompleteSources);

        wrapper = constructWrapper({
          autoCompleteSources,
          confidential: false,
        });

        expect(wrapper.vm.transformedAutocompleteSources).toBe(autoCompleteSources);
      });

      it('returns autocomplete sources with query `confidential_only`, when it is confidential', () => {
        wrapper = constructWrapper({
          autoCompleteSources,
          confidential: true,
        });

        const actualSources = wrapper.vm.transformedAutocompleteSources;

        expect(actualSources.epics).toContain('?confidential_only=true');
        expect(actualSources.issues).toContain('?confidential_only=true');
      });
    });
  });
});
