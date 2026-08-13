import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { MOCK_ISSUE, MOCK_EPIC, MOCK_WORK_ITEM, MOCK_MERGE_REQUEST } from '../../mock_data';

describe('IssuablePresenter', () => {
  let wrapper;

  useMockLocationHelper();

  beforeEach(() => {
    window.location.href = 'https://gitlab.com/gitlab-org/gitlab-shell/-/issues/1';
    window.location.origin = 'https://gitlab.com';
  });

  const createWrapper = ({ data }) => {
    wrapper = mountExtended(IssuablePresenter, {
      propsData: { data },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  describe.each`
    type               | mockData              | expectedText
    ${'issue'}         | ${MOCK_ISSUE}         | ${'Issue 1 (gitlab-test#1)'}
    ${'issue'}         | ${MOCK_WORK_ITEM}     | ${'Issue 1 (gitlab-test#1)'}
    ${'epic'}          | ${MOCK_EPIC}          | ${'Epic 1 (gitlab-org&1)'}
    ${'merge_request'} | ${MOCK_MERGE_REQUEST} | ${'Merge request 1 (gitlab-test!1)'}
  `('when rendering an $type', ({ mockData, type, expectedText }) => {
    it(`correctly renders a link containing the ${type} information`, () => {
      createWrapper({ data: mockData });

      const link = findLink();

      expect(link.attributes('href')).toBe(mockData.webUrl);
      expect(link.text()).toEqual(expectedText);
    });

    it(`correctly renders the state if the ${type} is closed`, () => {
      createWrapper({ data: { ...mockData, state: 'closed' } });

      const link = wrapper.findComponent(GlLink);

      expect(link.text()).toContain('closed');
    });
  });

  it('correctly renders a merged merge request', () => {
    createWrapper({ data: { ...MOCK_MERGE_REQUEST, state: 'merged' } });

    expect(findLink().text()).toContain('merged');
  });
});
