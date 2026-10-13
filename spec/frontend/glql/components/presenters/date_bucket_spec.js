import { mountExtended } from 'helpers/vue_test_utils_helper';
import DateBucketPresenter from '~/glql/components/presenters/date_bucket.vue';

describe('DateBucketPresenter', () => {
  const createWrapper = (propsData) => mountExtended(DateBucketPresenter, { propsData });

  // Cells always carry the year: unlike a chart axis, a table has no shared
  // context to disambiguate year-less labels. A weekly bucket catches both a
  // dropped year ("Jan 12 - 18") and a lost granularity ("Jan 12, 2026").
  it('renders the bucket as a date-only label with the year', () => {
    const wrapper = createWrapper({
      data: '2026-01-12',
      parameters: { granularity: 'weekly' },
    });

    expect(wrapper.text()).toBe('Jan 12 – 18, 2026');
  });
});
