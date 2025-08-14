import {
  GlFormRadio,
  GlFormRadioGroup,
  GlFormGroup,
  GlCollapsibleListbox,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PoliciesSelector from '~/token_access/components/policies_selector.vue';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';
import { POLICIES_BY_RESOURCE } from './mock_data';

describe('Policies selector component', () => {
  let wrapper;

  const createWrapper = ({
    isDefaultPermissionsSelected = false,
    jobTokenPolicies = [],
    disabled = false,
    stubs = {},
  } = {}) => {
    wrapper = shallowMountExtended(PoliciesSelector, {
      propsData: { isDefaultPermissionsSelected, jobTokenPolicies, disabled },
      stubs: {
        GlSprintf,
        GlFormGroup: stubComponent(GlFormGroup, {
          template: RENDER_ALL_SLOTS_TEMPLATE,
          props: ['label'],
        }),
        ...stubs,
      },
    });

    return waitForPromises();
  };

  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findDefaultRadio = () => wrapper.findByTestId('default-radio');
  const findFineGrainedRadio = () => wrapper.findByTestId('fine-grained-radio');
  const findResourcesFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findResourcesDescription = () =>
    findResourcesFormGroup().find('[data-testid="slot-label-description"]');
  const findPoliciesList = () => wrapper.find('ul');
  const findPolicyAt = (index) => findPoliciesList().findAll('li').at(index);
  const findPolicyDropdownAt = (index) => findPolicyAt(index).findComponent(GlCollapsibleListbox);

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
      ${'default'}      | ${true}  | ${findDefaultRadio}     | ${'Default permissions Job token inherits permissions from user role and membership.'}
      ${'fine-grained'} | ${false} | ${findFineGrainedRadio} | ${"Fine-grained permissions Job token permissions are limited to user's role and selected resource and scopes."}
    `('shows the $name radio', ({ value, findRadio, expectedText }) => {
      expect(findRadio().text()).toMatchInterpolatedText(expectedText);
      expect(findRadio().props('value')).toBe(value);
    });
  });

  describe('when Default permissions is selected', () => {
    beforeEach(() => createWrapper({ isDefaultPermissionsSelected: true }));

    it('does not show resources and scope form group', () => {
      expect(findResourcesFormGroup().exists()).toBe(false);
    });
  });

  describe('when Fine-grained permissions is selected', () => {
    beforeEach(() => createWrapper());

    describe('resources and scope form group', () => {
      it('shows form group', () => {
        expect(findResourcesFormGroup().props('label')).toBe('Select resources and scope');
      });

      it('shows description', () => {
        expect(findResourcesDescription().text()).toBe('Learn more about available API endpoints.');
      });

      it('shows description link', () => {
        const link = findResourcesDescription().findComponent(GlLink);

        expect(link.text()).toBe('API endpoints');
        expect(link.props()).toMatchObject({
          href: '/help/ci/jobs/fine_grained_permissions#available-api-endpoints',
          target: '_blank',
        });
      });
    });

    describe('policies dropdowns', () => {
      describe.each(POLICIES_BY_RESOURCE)('for resource $resource.text', (item) => {
        const index = POLICIES_BY_RESOURCE.indexOf(item);

        it('shows the resource name', () => {
          expect(findPolicyAt(index).text()).toBe(item.resource.text);
        });

        it('shows the resource dropdown', () => {
          expect(findPolicyDropdownAt(index).props('items')).toEqual(item.policies);
        });

        it.each(item.policies)(`emits $value policy when it is selected`, (policy) => {
          const expected = policy.value ? [policy.value] : [];
          findPolicyDropdownAt(index).vm.$emit('select', policy.value);

          expect(wrapper.emitted('update:jobTokenPolicies')[0][0]).toEqual(expected);
        });
      });

      describe('when multiple policies are selected across different resources', () => {
        const jobTokenPolicies = ['READ_JOBS', 'ADMIN_PACKAGES'];

        beforeEach(() => wrapper.setProps({ jobTokenPolicies }));

        it('adds the policy when there is no policy set for the resource', () => {
          findPolicyDropdownAt(5).vm.$emit('select', 'READ_RELEASES');

          expect(wrapper.emitted('update:jobTokenPolicies')[0][0]).toEqual([
            ...jobTokenPolicies,
            'READ_RELEASES',
          ]);
        });

        it('updates the policy when there is already a policy for the resource', () => {
          findPolicyDropdownAt(2).vm.$emit('select', 'ADMIN_JOBS');

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
