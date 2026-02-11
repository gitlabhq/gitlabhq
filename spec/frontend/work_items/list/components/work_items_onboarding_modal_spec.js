import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import WorkItemsOnboardingModal from '~/work_items/components/work_items_onboarding_modal/work_items_onboarding_modal.vue';
import Introduction from '~/work_items/components/work_items_onboarding_modal/animations/introduction.vue';
import Filters from '~/work_items/components/work_items_onboarding_modal/animations/filters.vue';
import SaveView from '~/work_items/components/work_items_onboarding_modal/animations/save_view.vue';

jest.useFakeTimers();

describe('WorkItemsOnboardingModal', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(WorkItemsOnboardingModal, {
      stubs: {
        GlModal: stubComponent(GlModal, {
          template: '<div><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findBackButton = () => wrapper.findByText('Back');
  const findNextButton = () => wrapper.findByTestId('next-button');
  const findStepIndicators = () => wrapper.findAll('.step-indicators span');
  const findStepTitle = () => wrapper.find('h2');
  const findStepBody = () => wrapper.find('p');

  const clickNext = async () => {
    findNextButton().trigger('click');
    jest.advanceTimersByTime(150);
    await nextTick();
  };

  const clickBack = async () => {
    findBackButton().trigger('click');
    jest.advanceTimersByTime(150);
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  describe('initial rendering', () => {
    it('renders the modal', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('renders the first step by default', () => {
      expect(wrapper.findComponent(Introduction).exists()).toBe(true);
      expect(findStepTitle().text()).toBe('Introducing the work items list');
      expect(findStepBody().text()).toContain('Epics, issues, and tasks are now work items');
    });

    it('renders 3 step indicators', () => {
      expect(findStepIndicators()).toHaveLength(3);
    });

    it('does not show Back button on first step', () => {
      expect(findBackButton().exists()).toBe(false);
    });

    it('shows Next button with "Next" text', () => {
      expect(findNextButton().text()).toBe('Next');
    });

    it('highlights the first step indicator', () => {
      expect(findStepIndicators().at(0).classes()).toContain('gl-bg-neutral-950');
      expect(findStepIndicators().at(1).classes()).toContain('gl-bg-neutral-200');
      expect(findStepIndicators().at(2).classes()).toContain('gl-bg-neutral-200');
    });
  });

  describe('step navigation - forward', () => {
    it('advances to step 2 when clicking Next', async () => {
      await clickNext();

      expect(wrapper.findComponent(Filters).exists()).toBe(true);
    });

    it('advances to step 3 when clicking Next twice', async () => {
      await clickNext();
      await clickNext();

      expect(wrapper.findComponent(SaveView).exists()).toBe(true);
      expect(findStepTitle().text()).toBe('All work items in one place');
    });

    it('changes Next button text to "Get Started" on the last step', async () => {
      await clickNext();
      await clickNext();
      await clickNext();

      expect(findNextButton().text()).toBe('Get Started');
    });

    it('updates step indicators correctly when advancing', async () => {
      await clickNext();

      expect(findStepIndicators().at(0).classes()).toContain('gl-bg-neutral-200');
      expect(findStepIndicators().at(1).classes()).toContain('gl-bg-neutral-950');
      expect(findStepIndicators().at(2).classes()).toContain('gl-bg-neutral-200');
    });
  });

  describe('step navigation - backward', () => {
    beforeEach(async () => {
      await clickNext();
    });

    it('shows Back button after first step', () => {
      expect(findBackButton().exists()).toBe(true);
      expect(findBackButton().text()).toBe('Back');
    });

    it('goes back to previous step when clicking Back', async () => {
      expect(wrapper.findComponent(Filters).exists()).toBe(true);

      await clickBack();

      expect(wrapper.findComponent(Introduction).exists()).toBe(true);
      expect(findStepTitle().text()).toBe('Introducing the work items list');
    });

    it('hides Back button when returning to first step', async () => {
      await clickBack();

      expect(findBackButton().exists()).toBe(false);
    });

    it('updates step indicators correctly when going back', async () => {
      await clickBack();

      expect(findStepIndicators().at(0).classes()).toContain('gl-bg-neutral-950');
      expect(findStepIndicators().at(1).classes()).toContain('gl-bg-neutral-200');
    });
  });

  describe('modal completion', () => {
    it('emits close event when clicking "Get Started" on last step', async () => {
      await clickNext();
      await clickNext();

      findNextButton().trigger('click');
      await nextTick();

      expect(wrapper.emitted('close')).toHaveLength(1);
    });

    it('emits close event when modal is hidden', () => {
      findModal().vm.$emit('hide');

      expect(wrapper.emitted('close')).toHaveLength(1);
    });
  });
});
