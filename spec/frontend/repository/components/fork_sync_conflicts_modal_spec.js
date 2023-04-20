import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ConflictsModal, { i18n } from '~/repository/components/fork_sync_conflicts_modal.vue';
import { propsConflictsModal } from '../mock_data';

describe('ConflictsModal', () => {
  let wrapper;

  function createComponent({ props = {} } = {}) {
    wrapper = shallowMount(ConflictsModal, {
      propsData: props,
      stubs: { GlModal },
    });
  }

  beforeEach(() => {
    createComponent({ props: propsConflictsModal });
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findInstructions = () => wrapper.findAll('[ data-testid="resolve-conflict-instructions"]');

  it('renders a modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('passes title as a prop to a gl-modal component', () => {
    expect(findModal().props().title).toBe(i18n.modalTitle);
  });

  it('renders a selection of markdown fields', () => {
    expect(findInstructions().length).toBe(3);
  });

  it('renders a source url in a first intruction', () => {
    expect(findInstructions().at(0).text()).toContain(propsConflictsModal.sourcePath);
  });

  it('renders default branch name in a first step intruction', () => {
    expect(findInstructions().at(0).text()).toContain(propsConflictsModal.sourceDefaultBranch);
  });

  it('renders selected branch name in a second step intruction', () => {
    expect(findInstructions().at(1).text()).toContain(propsConflictsModal.selectedBranch);
  });
});
