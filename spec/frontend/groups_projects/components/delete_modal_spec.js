import { GlFormInput, GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupsProjectsDeleteModal from '~/groups_projects/components/delete_modal.vue';
import { stubComponent } from 'helpers/stub_component';
import { useFakeDate } from 'helpers/fake_date';
import { RESOURCE_TYPES } from '~/groups_projects/constants';

jest.mock('lodash/uniqueId', () => (prefix) => `${prefix}fake-id`);

describe('GroupsProjectsDeleteModal', () => {
  useFakeDate(2025, 9, 29);

  let wrapper;

  const defaultPropsData = {
    resourceType: RESOURCE_TYPES.PROJECT,
    visible: false,
    confirmPhrase: 'foo',
    confirmLoading: false,
    fullName: 'Foo / Bar',
    markedForDeletion: false,
    permanentDeletionDate: '2025-11-28',
  };

  const createComponent = (propsData) => {
    wrapper = mountExtended(GroupsProjectsDeleteModal, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      stubs: {
        GlModal: stubComponent(GlModal),
      },
      scopedSlots: {
        alert: '<div data-testid="alert-slot"></div>',
        'restore-help-page-link':
          '<div data-testid="restore-help-page-link">{{ props.content }}</div>',
      },
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);
  const findFormInput = () => wrapper.findComponent(GlFormInput);
  const findModalBodyMessage = () => wrapper.findByTestId('modal-body-message');

  describe.each`
    resourceType              | expectedDeleteDelayedMessage                                                                                                                                                                   | expectedDeletePermanentlyMessage
    ${RESOURCE_TYPES.PROJECT} | ${`This action will place this project, including all its resources, in a pending deletion state for 30 days, and delete it permanently on ${defaultPropsData.permanentDeletionDate}.`}        | ${`This project is scheduled for deletion on ${defaultPropsData.permanentDeletionDate}. This action will permanently delete this project, including all its resources, immediately. This action cannot be undone.`}
    ${RESOURCE_TYPES.GROUP}   | ${`This action will place this group, including its subgroups and projects, in a pending deletion state for 30 days, and delete it permanently on ${defaultPropsData.permanentDeletionDate}.`} | ${`This group is scheduled for deletion on ${defaultPropsData.permanentDeletionDate}. This action will permanently delete this group, including its subgroups and projects, immediately. This action cannot be undone.`}
  `(
    'when resourceType is $resourceType',
    ({ resourceType, expectedDeleteDelayedMessage, expectedDeletePermanentlyMessage }) => {
      it('renders modal with correct props', () => {
        createComponent({ resourceType });

        expect(findGlModal().props()).toMatchObject({
          visible: defaultPropsData.visible,
          modalId: `delete-modal-fake-id`,
          actionPrimary: {
            text: `Yes, delete ${resourceType}`,
            attributes: {
              variant: 'danger',
              disabled: true,
              'data-testid': 'confirm-delete-button',
            },
          },
          actionCancel: {
            text: `Cancel, keep ${resourceType}`,
          },
        });
      });

      describe('when markedForDeletion prop is false', () => {
        beforeEach(() => {
          createComponent({ resourceType });
        });

        it('renders message', () => {
          expect(findModalBodyMessage().text()).toContain(expectedDeleteDelayedMessage);
        });
      });

      describe('when markedForDeletion prop is true', () => {
        it('renders message', () => {
          createComponent({
            resourceType,
            markedForDeletion: true,
          });

          expect(findModalBodyMessage().text()).toContain(expectedDeletePermanentlyMessage);
        });
      });
    },
  );

  it('renders alert slot', () => {
    createComponent();

    expect(wrapper.findByTestId('alert-slot').exists()).toBe(true);
  });

  describe('when correct confirm phrase is used', () => {
    beforeEach(() => {
      createComponent();

      findFormInput().vm.$emit('input', defaultPropsData.confirmPhrase);
    });

    it('enables the primary action', () => {
      expect(findGlModal().props('actionPrimary').attributes.disabled).toBe(false);
    });
  });

  describe('when correct confirm phrase is not used', () => {
    beforeEach(() => {
      createComponent();

      findFormInput().vm.$emit('input', 'bar');
    });

    it('keeps the primary action disabled', () => {
      expect(findGlModal().props('actionPrimary').attributes.disabled).toBe(true);
    });
  });

  it('emits `primary` with .prevent event', () => {
    createComponent();

    findGlModal().vm.$emit('primary', {
      preventDefault: jest.fn(),
    });

    expect(wrapper.emitted('primary')).toEqual([[]]);
  });

  it('emits `change` event', () => {
    createComponent();

    findGlModal().vm.$emit('change', true);

    expect(wrapper.emitted('change')).toEqual([[true]]);
  });

  it('renders aria-label', () => {
    createComponent();

    expect(findGlModal().props('ariaLabel')).toBe('Delete Foo / Bar');
  });

  it('when confirmLoading switches from true to false, emits `change event`', async () => {
    createComponent({ confirmLoading: true });

    // setProps is justified here because we are testing the component's
    // reactive behavior which constitutes an exception
    // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
    wrapper.setProps({ confirmLoading: false });

    await nextTick();

    expect(wrapper.emitted('change')).toEqual([[false]]);
  });
});
