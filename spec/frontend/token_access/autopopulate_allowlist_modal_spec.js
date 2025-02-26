import { GlAlert, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createMockDirective } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AutopopulateAllowlistMutation from '~/token_access/graphql/mutations/autopopulate_allowlist.mutation.graphql';
import AutopopulateAllowlistModal from '~/token_access/components/autopopulate_allowlist_modal.vue';
import { mockAutopopulateAllowlistResponse, mockAutopopulateAllowlistError } from './mock_data';

const projectName = 'My project';
const fullPath = 'root/my-repo';

Vue.use(VueApollo);
const mockToastShow = jest.fn();

describe('AutopopulateAllowlistModal component', () => {
  let wrapper;
  let mockApollo;
  let mockAutopopulateMutation;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props } = {}) => {
    const handlers = [[AutopopulateAllowlistMutation, mockAutopopulateMutation]];
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(AutopopulateAllowlistModal, {
      apolloProvider: mockApollo,
      provide: {
        fullPath,
      },
      mocks: {
        $toast: { show: mockToastShow },
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        authLogExceedsLimit: false,
        projectAllowlistLimit: 4,
        projectName,
        showModal: true,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    mockAutopopulateMutation = jest.fn();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render alert or help link by default', () => {
      expect(findAlert().exists()).toBe(false);
      expect(findLink().exists()).toBe(false);
    });

    it('renders the default title', () => {
      expect(findModal().props('title')).toBe(
        'Add all authentication log entries to the allowlist',
      );
    });

    describe('when autopopulating will exceed the allowlist limit', () => {
      beforeEach(() => {
        createComponent({ props: { authLogExceedsLimit: true } });
      });

      it('renders the correct title', () => {
        expect(findModal().props('title')).toBe('Add log entries and compact the allowlist');
      });

      it('renders warning alert', () => {
        expect(findAlert().text()).toBe(
          'The allowlist can contain a maximum of 4 groups and projects.',
        );
      });

      it('renders help link', () => {
        expect(findLink().text()).toBe('What is the compaction algorithm?');
        expect(findLink().attributes('href')).toBe(
          '/help/ci/jobs/ci_job_token#auto-populate-a-projects-allowlist',
        );
      });
    });

    it.each`
      modalEvent     | emittedEvent
      ${'canceled'}  | ${'hide'}
      ${'hidden'}    | ${'hide'}
      ${'secondary'} | ${'hide'}
    `(
      'emits the $emittedEvent event when $modalEvent event is triggered',
      ({ modalEvent, emittedEvent }) => {
        expect(wrapper.emitted(emittedEvent)).toBeUndefined();

        findModal().vm.$emit(modalEvent);

        expect(wrapper.emitted(emittedEvent)).toHaveLength(1);
      },
    );
  });

  describe('when mutation is running', () => {
    beforeEach(() => {
      mockAutopopulateMutation.mockResolvedValue(mockAutopopulateAllowlistResponse);
      createComponent();
    });

    it('shows loading state for confirm button and disables cancel button', async () => {
      expect(findModal().props('actionPrimary').attributes).toMatchObject({ loading: false });
      expect(findModal().props('actionSecondary').attributes).toMatchObject({ disabled: false });

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();

      expect(findModal().props('actionPrimary').attributes).toMatchObject({ loading: true });
      expect(findModal().props('actionSecondary').attributes).toMatchObject({ disabled: true });
    });
  });

  describe('when mutation is successful', () => {
    beforeEach(async () => {
      mockAutopopulateMutation.mockResolvedValue(mockAutopopulateAllowlistResponse);

      createComponent();
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
    });

    it('calls the mutation', () => {
      expect(mockAutopopulateMutation).toHaveBeenCalledWith({ projectPath: fullPath });
    });

    it('shows toast message', () => {
      expect(mockToastShow).toHaveBeenCalledWith(
        'Authentication log entries were successfully added to the allowlist.',
      );
    });

    it('emits events for refetching data and hiding modal', () => {
      expect(wrapper.emitted('refetch-allowlist')).toHaveLength(1);
      expect(wrapper.emitted('hide')).toHaveLength(1);
    });
  });

  describe('when mutation fails', () => {
    beforeEach(async () => {
      createComponent();
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();

      mockAutopopulateMutation.mockResolvedValue(mockAutopopulateAllowlistError);
    });

    it('renders alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('does not render toast message or emit events', () => {
      expect(mockToastShow).not.toHaveBeenCalledWith();
      expect(wrapper.emitted('refetch-allowlist')).toBeUndefined();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });
});
