import { GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import IssuableStats from '~/releases/components/issuable_stats.vue';

describe('~/releases/components/issuable_stats.vue', () => {
  let wrapper;
  let defaultProps;

  const createComponent = (propUpdates) => {
    wrapper = mount(IssuableStats, {
      propsData: {
        ...defaultProps,
        ...propUpdates,
      },
    });
  };

  const findOpenStatLink = () => wrapper.find('[data-testid="open-stat"]').findComponent(GlLink);
  const findMergedStatLink = () =>
    wrapper.find('[data-testid="merged-stat"]').findComponent(GlLink);
  const findClosedStatLink = () =>
    wrapper.find('[data-testid="closed-stat"]').findComponent(GlLink);

  beforeEach(() => {
    defaultProps = {
      label: 'Items',
      total: 10,
      closed: 2,
      merged: 7,
      openedPath: 'path/to/opened/items',
      closedPath: 'path/to/closed/items',
      mergedPath: 'path/to/merged/items',
    };
  });

  it('matches snapshot', () => {
    createComponent();

    expect(wrapper.html()).toMatchSnapshot();
  });

  describe('when only total and closed counts are provided', () => {
    beforeEach(() => {
      createComponent({ merged: undefined, mergedPath: undefined });
    });

    it('renders a label with the total count; also, the opened count and the closed count', () => {
      expect(trimText(wrapper.text())).toMatchInterpolatedText('Items 10 Open: 8 • Closed: 2');
    });
  });

  describe('when only total, merged, and closed counts are provided', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a label with the total count; also, the opened count, the merged count, and the closed count', () => {
      expect(wrapper.text()).toMatchInterpolatedText('Items 10 Open: 1 • Merged: 7 • Closed: 2');
    });
  });

  describe('when path parameters are provided', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the "open" stat as a link', () => {
      const link = findOpenStatLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(defaultProps.openedPath);
    });

    it('renders the "merged" stat as a link', () => {
      const link = findMergedStatLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(defaultProps.mergedPath);
    });

    it('renders the "closed" stat as a link', () => {
      const link = findClosedStatLink();

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(defaultProps.closedPath);
    });
  });

  describe('when path parameters are not provided', () => {
    beforeEach(() => {
      createComponent({
        openedPath: undefined,
        closedPath: undefined,
        mergedPath: undefined,
      });
    });

    it('does not render the "open" stat as a link', () => {
      expect(findOpenStatLink().exists()).toBe(false);
    });

    it('does not render the "merged" stat as a link', () => {
      expect(findMergedStatLink().exists()).toBe(false);
    });

    it('does not render the "closed" stat as a link', () => {
      expect(findClosedStatLink().exists()).toBe(false);
    });
  });
});
