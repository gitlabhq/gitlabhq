import { GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DuoReadinessRow from '~/ai/settings/readiness/components/duo_readiness_row.vue';

describe('DuoReadinessRow', () => {
  let wrapper;

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMountExtended(DuoReadinessRow, {
      propsData: { title: 'Agent Platform', status: 'done', ...props },
      slots,
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTitle = () => wrapper.findByTestId('readiness-row-title');
  const findDescription = () => wrapper.findByTestId('readiness-row-description');
  const findRow = () => wrapper.findByTestId('readiness-row');
  const findRowControl = () => wrapper.findByTestId('readiness-row-control');
  const findCascadingLock = () => wrapper.findByTestId('lock');
  const findStatusColumn = () => wrapper.findByTestId('readiness-row-status');
  const findNote = () => wrapper.findByTestId('readiness-row-note');

  it('renders the title and description', () => {
    createComponent({ description: 'On for this group.' });

    expect(findTitle().text()).toBe('Agent Platform');
    expect(findDescription().text()).toBe('On for this group.');
  });

  it.each`
    status       | icon                     | variant
    ${'done'}    | ${'check-circle-filled'} | ${'success'}
    ${'todo'}    | ${'check-circle-dashed'} | ${'subtle'}
    ${'blocked'} | ${'dash-circle'}         | ${'disabled'}
    ${'error'}   | ${'error'}               | ${'danger'}
  `('shows the $status icon', ({ status, icon, variant }) => {
    createComponent({ status });

    expect(findIcon().props()).toMatchObject({ name: icon, variant });
  });

  it('shows a spinner instead of a status icon while the row state is loading', () => {
    createComponent({ status: 'loading' });

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    expect(findIcon().exists()).toBe(false);
  });

  it('mutes the title while the row is blocked on a prerequisite', () => {
    createComponent({ status: 'blocked' });

    expect(findTitle().classes()).toContain('gl-text-subtle');
  });

  it('keeps the status column but shows no icon for a row that is not a step', () => {
    createComponent({ status: null });

    expect(findStatusColumn().exists()).toBe(true);
    expect(findIcon().exists()).toBe(false);
    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
  });

  describe('when the parent setting is off', () => {
    beforeEach(() => {
      createComponent({ status: 'done', disabled: true });
    });

    it('mutes the title', () => {
      expect(findTitle().classes()).toContain('gl-text-subtle');
    });

    it('shows the inactive icon regardless of the stored status', () => {
      expect(findIcon().props()).toMatchObject({
        name: 'check-circle-dashed',
        variant: 'disabled',
      });
    });

    it('passes the disabled state to the control slot', () => {
      wrapper = shallowMountExtended(DuoReadinessRow, {
        propsData: { title: 'Agent Platform', disabled: true },
        scopedSlots: {
          default: '<button :disabled="props.disabled" data-testid="control"></button>',
        },
      });

      expect(findRowControl().find('button').attributes('disabled')).toBe('disabled');
    });
  });

  it('renders the note slot as a third line', () => {
    createComponent({}, { note: '<span data-testid="inherited">Inherited: On by default</span>' });

    expect(findNote().text()).toBe('Inherited: On by default');
  });

  it('renders no note line without note content', () => {
    createComponent();

    expect(findNote().exists()).toBe(false);
  });

  it('indents a nested row so it reads as qualifying the row above it', () => {
    createComponent({ nested: true });

    expect(findRow().classes()).toContain('gl-pl-9');
    expect(findRow().classes()).toContain('gl-bg-subtle');
  });

  it('renders the control slot, so a row can carry a toggle or a button', () => {
    createComponent({}, { default: '<button data-testid="control">Generate</button>' });

    expect(findRowControl().text()).toBe('Generate');
  });

  it('renders the title-icon slot for a cascading lock', () => {
    createComponent({}, { 'title-icon': '<span data-testid="lock">locked</span>' });

    expect(findCascadingLock().exists()).toBe(true);
  });

  it('lets the description slot override the plain text, for inline help links', () => {
    createComponent(
      { description: 'plain' },
      { description: '<a href="/help">What are flows?</a>' },
    );

    expect(findDescription().text()).toBe('What are flows?');
    expect(findDescription().find('a').attributes()).toMatchObject({ href: '/help' });
  });
});
