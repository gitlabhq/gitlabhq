import { GlTableLite, GlFormRadio, GlFormRadioGroup, GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PoliciesSelector, { TABLE_FIELDS } from '~/token_access/components/policies_selector.vue';
import { stubComponent } from 'helpers/stub_component';
import { POLICIES_BY_RESOURCE, RESOURCE_JOBS, RESOURCE_RELEASES } from '~/token_access/constants';

describe('Policies selector component', () => {
  let wrapper;

  const createWrapper = ({
    isDefaultPermissionsSelected = false,
    jobTokenPolicies = [],
    disabled = false,
    stubs = {},
  } = {}) => {
    wrapper = mountExtended(PoliciesSelector, {
      propsData: { isDefaultPermissionsSelected, jobTokenPolicies, disabled },
      stubs,
    });

    return waitForPromises();
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findDefaultRadio = () => wrapper.findByTestId('default-radio');
  const findFineGrainedRadio = () => wrapper.findByTestId('fine-grained-radio');

  const getResourceIndex = (item) =>
    POLICIES_BY_RESOURCE.map(({ resource }) => resource).indexOf(item);

  const findNameForResource = (resource) =>
    findTable().findAll('tbody tr').at(getResourceIndex(resource)).findAll('td').at(0);

  const findPolicyDropdownForResource = (resource) =>
    wrapper.findAllComponents(GlCollapsibleListbox).at(getResourceIndex(resource));

  describe('permission type radio options', () => {
    beforeEach(() =>
      createWrapper({
        stubs: {
          GlFormRadioGroup: stubComponent(GlFormRadioGroup, { props: ['checked'] }),
          GlFormRadio: stubComponent(GlFormRadio, {
            template: '<div><slot></slot><slot name="help"></slot></div>',
            props: ['value'],
          }),
        },
      }),
    );

    describe('radio group', () => {
      it('shows radio group', () => {
        expect(findRadioGroup().exists()).toBe(true);
      });

      it.each`
        name              | isDefaultPermissionsSelected
        ${'default'}      | ${true}
        ${'fine-grained'} | ${false}
      `(
        'selects the $name option when the isDefaultPermissionsSelected prop is $isDefaultPermissionsSelected',
        async ({ isDefaultPermissionsSelected }) => {
          await wrapper.setProps({ isDefaultPermissionsSelected });

          expect(findRadioGroup().props('checked')).toBe(isDefaultPermissionsSelected);
        },
      );

      it.each`
        name              | isDefaultPermissionsSelected
        ${'default'}      | ${true}
        ${'fine-grained'} | ${false}
      `(
        'emits update:isDefaultPermissionsSelected event with $isDefaultPermissionsSelected when $name is selected',
        ({ isDefaultPermissionsSelected }) => {
          findRadioGroup().vm.$emit('change', isDefaultPermissionsSelected);

          expect(wrapper.emitted('update:isDefaultPermissionsSelected')[0][0]).toEqual(
            isDefaultPermissionsSelected,
          );
        },
      );
    });

    it.each`
      name              | value    | findRadio               | expectedText
      ${'default'}      | ${true}  | ${findDefaultRadio}     | ${'Default permissions Use the standard permissions model based on user membership and roles.'}
      ${'fine-grained'} | ${false} | ${findFineGrainedRadio} | ${'Fine-grained permissions Apply permissions that grant access to individual resources.'}
    `('shows the $name radio', ({ value, findRadio, expectedText }) => {
      expect(findRadio().text()).toMatchInterpolatedText(expectedText);
      expect(findRadio().props('value')).toBe(value);
    });
  });

  describe('when Default permissions is selected', () => {
    beforeEach(() => createWrapper({ isDefaultPermissionsSelected: true }));

    it('does not show policies table', () => {
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('when Fine-grained permissions is selected', () => {
    beforeEach(() => {
      createWrapper({
        stubs: { GlTableLite: stubComponent(GlTableLite, { props: ['fields', 'items'] }) },
      });
    });

    it('shows policies table', () => {
      expect(findTable().props()).toMatchObject({
        items: POLICIES_BY_RESOURCE,
        fields: TABLE_FIELDS,
      });
    });

    describe('policies table', () => {
      beforeEach(() => createWrapper());

      describe.each(POLICIES_BY_RESOURCE)(
        'for resource $resource.text',
        ({ resource, policies }) => {
          it('shows the resource name', () => {
            expect(findNameForResource(resource).text()).toBe(resource.text);
          });

          it('shows the resource dropdown', () => {
            expect(findPolicyDropdownForResource(resource).props('items')).toEqual(policies);
          });

          it.each(policies)(`emits $value policy when it is selected`, (policy) => {
            const expected = policy.value ? [policy.value] : [];
            findPolicyDropdownForResource(resource).vm.$emit('select', policy.value);

            expect(wrapper.emitted('update:jobTokenPolicies')[0][0]).toEqual(expected);
          });
        },
      );

      describe('when multiple policies are selected across different resources', () => {
        const jobTokenPolicies = ['READ_JOBS', 'ADMIN_PACKAGES'];

        beforeEach(() => wrapper.setProps({ jobTokenPolicies }));

        it('adds the policy when there is no policy set for the resource', () => {
          findPolicyDropdownForResource(RESOURCE_RELEASES).vm.$emit('select', 'READ_RELEASES');

          expect(wrapper.emitted('update:jobTokenPolicies')[0][0]).toEqual([
            ...jobTokenPolicies,
            'READ_RELEASES',
          ]);
        });

        it('updates the policy when there is already a policy for the resource', () => {
          findPolicyDropdownForResource(RESOURCE_JOBS).vm.$emit('select', 'ADMIN_JOBS');

          expect(wrapper.emitted('update:jobTokenPolicies')[0][0]).toEqual([
            'ADMIN_JOBS',
            'ADMIN_PACKAGES',
          ]);
        });
      });
    });

    describe('disabled prop', () => {
      describe.each([true, false])('when disabled prop is %s', (disabled) => {
        beforeEach(() =>
          createWrapper({
            disabled,
            stubs: { GlFormRadioGroup: stubComponent(GlFormRadioGroup, { props: ['disabled'] }) },
          }),
        );

        it(`sets radio group disabled to ${disabled}`, () => {
          expect(findRadioGroup().props('disabled')).toBe(disabled);
        });

        it(`sets all policy dropdowns disabled to ${disabled}`, () => {
          wrapper.findAllComponents(GlCollapsibleListbox).wrappers.forEach((dropdown) => {
            expect(dropdown.props('disabled')).toBe(disabled);
          });
        });
      });
    });
  });
});
