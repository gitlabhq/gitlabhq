import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlModal, GlFormInput, GlDatepicker, GlFormTextarea } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import CreateTimelogForm from '~/sidebar/components/time_tracking/create_timelog_form.vue';
import createTimelogMutation from '~/sidebar/queries/create_timelog.mutation.graphql';
import { TYPENAME_ISSUE, TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';

const mockMutationErrorMessage = 'Example error message';

const resolvedMutationWithoutErrorsMock = jest.fn().mockResolvedValue({
  data: {
    timelogCreate: {
      errors: [],
      timelog: {
        id: 'gid://gitlab/Timelog/1',
        issue: {},
        mergeRequest: {},
      },
    },
  },
});

const resolvedMutationWithErrorsMock = jest.fn().mockResolvedValue({
  data: {
    timelogCreate: {
      errors: [{ message: mockMutationErrorMessage }],
      timelog: null,
    },
  },
});

const rejectedMutationMock = jest.fn().mockRejectedValue();
const modalCloseMock = jest.fn();

describe('Create Timelog Form', () => {
  Vue.use(VueApollo);

  let wrapper;
  let fakeApollo;

  const findForm = () => wrapper.find('form');
  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDocsLink = () => wrapper.findByTestId('timetracking-docs-link');
  const findSaveButton = () => findModal().props('actionPrimary');
  const findSaveButtonLoadingState = () => findSaveButton().attributes.loading;
  const findSaveButtonDisabledState = () => findSaveButton().attributes.disabled;
  const findGlFormInput = () => wrapper.findComponent(GlFormInput);
  const findGlDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findGlFormTextarea = () => wrapper.findComponent(GlFormTextarea);

  const submitForm = () => findForm().trigger('submit');

  const mountComponent = (
    { props, providedProps } = {},
    mutationResolverMock = rejectedMutationMock,
  ) => {
    fakeApollo = createMockApollo([[createTimelogMutation, mutationResolverMock]]);

    wrapper = shallowMountExtended(CreateTimelogForm, {
      provide: {
        issuableType: 'issue',
        ...providedProps,
      },
      propsData: {
        issuableId: '1',
        ...props,
      },
      apolloProvider: fakeApollo,
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: { close: modalCloseMock },
        }),
      },
    });
  };

  afterEach(() => {
    fakeApollo = null;
    modalCloseMock.mockClear();
  });

  describe('save button', () => {
    it('is disabled and not loading by default', () => {
      mountComponent();

      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(true);
    });

    it('is enabled and not loading when time spent is not empty', async () => {
      mountComponent();

      await findGlFormInput().vm.$emit('input', '2d');

      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });

    it('is disabled and loading when the the form is submitted', async () => {
      mountComponent();
      await findGlFormInput().vm.$emit('input', '2d');

      submitForm();

      await nextTick();

      expect(findSaveButtonLoadingState()).toBe(true);
      expect(findSaveButtonDisabledState()).toBe(true);
    });

    it('is enabled and not loading the when form is submitted but the mutation has errors', async () => {
      mountComponent();
      await findGlFormInput().vm.$emit('input', '2d');

      submitForm();

      await waitForPromises();

      expect(rejectedMutationMock).toHaveBeenCalled();
      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });

    it('is enabled and not loading the when form is submitted but the mutation returns errors', async () => {
      mountComponent({}, resolvedMutationWithErrorsMock);
      await findGlFormInput().vm.$emit('input', '2d');

      submitForm();

      await waitForPromises();

      expect(resolvedMutationWithErrorsMock).toHaveBeenCalled();
      expect(findSaveButtonLoadingState()).toBe(false);
      expect(findSaveButtonDisabledState()).toBe(false);
    });
  });

  describe('form', () => {
    it('does not call any mutation when the the form is incomplete', async () => {
      mountComponent();

      submitForm();

      await waitForPromises();

      expect(rejectedMutationMock).not.toHaveBeenCalled();
    });

    it('closes the modal after a successful mutation', async () => {
      mountComponent({}, resolvedMutationWithoutErrorsMock);
      await findGlFormInput().vm.$emit('input', '2d');

      submitForm();

      await waitForPromises();
      await nextTick();

      expect(modalCloseMock).toHaveBeenCalled();
    });

    it.each`
      issuableType       | typeConstant
      ${'issue'}         | ${TYPENAME_ISSUE}
      ${'merge_request'} | ${TYPENAME_MERGE_REQUEST}
    `(
      'calls the mutation with all the fields when the the form is submitted and issuable type is $issuableType',
      async ({ issuableType, typeConstant }) => {
        const timeSpent = '2d';
        const spentAt = '2022-11-20T21:53:00+0000';
        const summary = 'Example';

        mountComponent({ providedProps: { issuableType } });
        await findGlFormInput().vm.$emit('input', timeSpent);
        await findGlDatepicker().vm.$emit('input', spentAt);
        await findGlFormTextarea().vm.$emit('input', summary);

        submitForm();

        await waitForPromises();

        expect(rejectedMutationMock).toHaveBeenCalledWith({
          input: { timeSpent, spentAt, summary, issuableId: convertToGraphQLId(typeConstant, '1') },
        });
      },
    );
  });

  describe('alert', () => {
    it('is hidden by default', () => {
      mountComponent();

      expect(findAlert().exists()).toBe(false);
    });

    it('shows an error if the submission fails with a handled error', async () => {
      mountComponent({}, resolvedMutationWithErrorsMock);
      await findGlFormInput().vm.$emit('input', '2d');

      submitForm();

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(mockMutationErrorMessage);
    });

    it('shows an error if the submission fails with an unhandled error', async () => {
      mountComponent();
      await findGlFormInput().vm.$emit('input', '2d');

      submitForm();

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe('An error occurred while saving the time entry.');
    });
  });

  describe('docs link message', () => {
    it('is present', () => {
      mountComponent();

      expect(findDocsLink().exists()).toBe(true);
    });
  });
});
