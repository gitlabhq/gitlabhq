import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RowDisclosureToggle from '~/vue_shared/components/expandable_rows/row_disclosure_toggle.vue';

describe('RowDisclosureToggle', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(RowDisclosureToggle, {
      propsData: { label: 'Platform', ...props },
      slots: { default: '<span data-testid="content">Platform</span>' },
    });
  };

  const findToggle = () => wrapper.findComponentByTestId('row-disclosure-toggle');
  const findPlaceholder = () => wrapper.findByTestId('row-disclosure-placeholder');

  it('renders the slot content', () => {
    createComponent();

    expect(wrapper.findByTestId('content').text()).toBe('Platform');
  });

  describe('when the row cannot expand', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a hidden placeholder instead of a toggle', () => {
      expect(findToggle().exists()).toBe(false);
      expect(findPlaceholder().attributes('aria-hidden')).toBe('true');
    });
  });

  describe('when the row is collapsed', () => {
    beforeEach(() => {
      createComponent({ expandable: true, childRowIds: ['row-1', 'row-2'] });
    });

    it('renders a right chevron with the collapsed state', () => {
      expect(findToggle().props('icon')).toBe('chevron-right');
      expect(findToggle().attributes()).toMatchObject({
        'aria-expanded': 'false',
        'aria-label': 'Rows under Platform',
      });
    });

    it('does not point at rows that are not rendered', () => {
      expect(findToggle().attributes('aria-controls')).toBeUndefined();
    });

    it('emits toggle on click', () => {
      findToggle().vm.$emit('click');

      expect(wrapper.emitted('toggle')).toHaveLength(1);
    });
  });

  describe('when the row is expanded', () => {
    beforeEach(() => {
      createComponent({ expandable: true, expanded: true, childRowIds: ['row-1', 'row-2'] });
    });

    it('renders a down chevron with the expanded state and the rows it controls', () => {
      expect(findToggle().props('icon')).toBe('chevron-down');
      expect(findToggle().attributes()).toMatchObject({
        'aria-expanded': 'true',
        'aria-label': 'Rows under Platform',
        'aria-controls': 'row-1 row-2',
      });
    });
  });

  it('does not escape the row name in the label', () => {
    createComponent({ expandable: true, label: "Issues & MR's" });

    expect(findToggle().attributes('aria-label')).toBe("Rows under Issues & MR's");
  });

  it('does not set aria-controls when an expanded row has no child rows', () => {
    createComponent({ expandable: true, expanded: true });

    expect(findToggle().attributes('aria-controls')).toBeUndefined();
  });

  it('passes the loading state to the button', () => {
    createComponent({ expandable: true, loading: true });

    expect(findToggle().props('loading')).toBe(true);
  });

  const findParentText = () => wrapper.findByTestId('row-disclosure-parent');

  it('tells screen readers which row a nested row is under', () => {
    createComponent({ depth: 1, parentLabel: 'Platform' });

    expect(findParentText().text()).toBe('Under Platform');
    expect(findParentText().classes()).toContain('gl-sr-only');
  });

  it.each`
    depth | parentLabel
    ${0}  | ${'Platform'}
    ${1}  | ${''}
  `(
    'does not name a parent at depth $depth with parent label "$parentLabel"',
    ({ depth, parentLabel }) => {
      createComponent({ depth, parentLabel });

      expect(findParentText().exists()).toBe(false);
    },
  );

  it.each`
    depth | style
    ${0}  | ${undefined}
    ${1}  | ${'padding-inline-start: 2rem;'}
    ${2}  | ${'padding-inline-start: 4rem;'}
  `('indents a row at depth $depth', ({ depth, style }) => {
    createComponent({ depth });

    expect(wrapper.attributes('style')).toBe(style);
  });
});
