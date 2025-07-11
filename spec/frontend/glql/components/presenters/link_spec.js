import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LinkPresenter from '~/glql/components/presenters/link.vue';
import { MOCK_ISSUE, MOCK_USER, MOCK_MILESTONE, MOCK_PROJECT, MOCK_GROUP } from '../../mock_data';

describe('LinkPresenter', () => {
  it.each`
    data              | linkHref                                                  | linkText
    ${MOCK_ISSUE}     | ${'https://gitlab.com/gitlab-org/gitlab-test/-/issues/1'} | ${'Issue 1'}
    ${MOCK_USER}      | ${'https://gitlab.com/foobar'}                            | ${'foobar'}
    ${MOCK_MILESTONE} | ${'/gitlab-org/gitlab-test/-/milestones/1'}               | ${'Milestone 1'}
    ${MOCK_PROJECT}   | ${'https://gitlab.com/gitlab-org/gitlab-test'}            | ${'GitLab Org / GitLab Test'}
    ${MOCK_GROUP}     | ${'https://gitlab.com/gitlab-org'}                        | ${'GitLab Org'}
  `('for data $data, it renders a link', ({ data, linkHref, linkText }) => {
    const wrapper = shallowMountExtended(LinkPresenter, { propsData: { data } });

    expect(wrapper.text()).toBe(linkText);
    expect(wrapper.attributes('href')).toBe(linkHref);
  });
});
