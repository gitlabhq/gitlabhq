import { GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DuoReadinessRow from '~/pages/projects/shared/permissions/components/duo_readiness_row.vue';

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
