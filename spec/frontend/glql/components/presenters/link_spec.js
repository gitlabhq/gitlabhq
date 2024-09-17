import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import { MOCK_ISSUE, MOCK_USER, MOCK_MILESTONE } from '../../mock_data';

describe('LinkPresenter', () => {
  it.each`
    data              | linkHref                                                  | linkText
    ${MOCK_ISSUE}     | ${'https://gitlab.com/gitlab-org/gitlab-test/-/issues/1'} | ${'Issue 1'}
    ${MOCK_USER}      | ${'https://gitlab.com/foobar'}                            | ${'foobar'}
    ${MOCK_MILESTONE} | ${'/gitlab-org/gitlab-test/-/milestones/1'}               | ${'Milestone 1'}
  `('for data $data, it renders a link', ({ data, linkHref, linkText }) => {
    const wrapper = shallowMountExtended(LinkPresenter, { propsData: { data } });

    expect(wrapper.text()).toBe(linkText);
    expect(wrapper.attributes('href')).toBe(linkHref);
  });

  it.each`
    scenario                       | data
    ${'for data without a webUrl'} | ${{ title: 'Issue 1' }}
    ${'for data without a title'}  | ${{ webUrl: 'https://gitlab.com' }}
  `('$scenario, it shows a warning in console', ({ data }) => {
    jest.spyOn(console, 'error').mockImplementation(() => {});

    shallowMountExtended(LinkPresenter, { propsData: { data } });

    // eslint-disable-next-line no-console
    expect(console.error.mock.calls[0][0]).toContain(
      '[Vue warn]: Invalid prop: custom validator check failed for prop "data"',
    );
  });

  describe.each`
    dataType    | data
    ${'String'} | ${'Hello, world!'}
    ${'Number'} | ${100}
    ${'Array'}  | ${[1, 2, 3]}
  `('for data type $dataType', ({ dataType, data }) => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation(() => {});
    });

    it('shows a warning in console for mismatched propType', () => {
      shallowMountExtended(LinkPresenter, { propsData: { data } });

      // eslint-disable-next-line no-console
      expect(console.error.mock.calls[0][0]).toContain(
        `[Vue warn]: Invalid prop: type check failed for prop "data". Expected Object, got ${dataType}`,
      );
    });
  });
});
