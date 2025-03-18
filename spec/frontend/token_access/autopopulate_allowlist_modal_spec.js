import { GlAlert, GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AutopopulateAllowlistModal from '~/token_access/components/autopopulate_allowlist_modal.vue';

const projectName = 'My project';
const fullPath = 'root/my-repo';

describe('AutopopulateAllowlistModal component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);
  const findLink = () => wrapper.findComponent(GlLink);

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMountExtended(AutopopulateAllowlistModal, {
      provide: {
        fullPath,
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
          '/help/ci/jobs/ci_job_token#allowlist-compaction',
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

  describe('when clicking on the primary button', () => {
    it('emits the remove-entries event', () => {
      createComponent();

      expect(wrapper.emitted('autopopulate-allowlist')).toBeUndefined();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });

      expect(wrapper.emitted('autopopulate-allowlist')).toHaveLength(1);
    });
  });
});
