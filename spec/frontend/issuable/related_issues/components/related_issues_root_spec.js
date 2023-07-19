import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import {
  defaultProps,
  issuable1,
  issuable2,
} from 'jest/issuable/components/related_issuable_mock_data';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_CONFLICT,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
import { linkedIssueTypesMap } from '~/related_issues/constants';
import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import RelatedIssuesRoot from '~/related_issues/components/related_issues_root.vue';

jest.mock('~/alert');

describe('RelatedIssuesRoot', () => {
  let wrapper;
  let mock;

  const findRelatedIssuesBlock = () => wrapper.findComponent(RelatedIssuesBlock);

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(defaultProps.endpoint).reply(HTTP_STATUS_OK, []);
  });

  afterEach(() => {
    mock.restore();
  });

  const createComponent = ({ props = {}, data = {} } = {}) => {
    wrapper = shallowMount(RelatedIssuesRoot, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        reportAbusePath: '/report/abuse/path',
      },
      data() {
        return data;
      },
    });

    // Wait for fetch request `fetchRelatedIssues` to complete before starting to test
    return waitForPromises();
  };

  describe('events', () => {
    describe('when "relatedIssueRemoveRequest" event is emitted', () => {
      describe('when emitted value is a numerical issue', () => {
        beforeEach(async () => {
          mock.onGet(defaultProps.endpoint).reply(HTTP_STATUS_OK, [issuable1]);
          await createComponent();
        });

        // quarantine: https://gitlab.com/gitlab-org/gitlab/-/issues/417177
        // eslint-disable-next-line jest/no-disabled-tests
        it.skip('removes related issue on API success', async () => {
          mock.onDelete(issuable1.referencePath).reply(HTTP_STATUS_OK, { issues: [] });

          findRelatedIssuesBlock().vm.$emit('relatedIssueRemoveRequest', issuable1.id);
          await axios.waitForAll();

          expect(findRelatedIssuesBlock().props('relatedIssues')).toEqual([]);
        });

        it('does not remove related issue on API error', async () => {
          mock.onDelete(issuable1.referencePath).reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, {});

          findRelatedIssuesBlock().vm.$emit('relatedIssueRemoveRequest', issuable1.id);
          await axios.waitForAll();

          expect(findRelatedIssuesBlock().props('relatedIssues')).toEqual([
            expect.objectContaining({ id: issuable1.id }),
          ]);
        });
      });

      describe('when emitted value is a work item id', () => {
        it('removes related issue', async () => {
          const workItem = `gid://gitlab/WorkItem/${issuable1.id}`;
          createComponent({ data: { state: { relatedIssues: [issuable1] } } });

          await findRelatedIssuesBlock().vm.$emit('relatedIssueRemoveRequest', workItem);

          expect(findRelatedIssuesBlock().props('relatedIssues')).toEqual([]);
        });
      });
    });

    describe('when "toggleAddRelatedIssuesForm" event is emitted', () => {
      it('toggles related issues form to visible from hidden', async () => {
        createComponent();

        await findRelatedIssuesBlock().vm.$emit('toggleAddRelatedIssuesForm');

        expect(findRelatedIssuesBlock().props('isFormVisible')).toBe(true);
      });

      it('toggles related issues form to hidden from visible', async () => {
        createComponent({ data: { isFormVisible: true } });

        await findRelatedIssuesBlock().vm.$emit('toggleAddRelatedIssuesForm');

        expect(findRelatedIssuesBlock().props('isFormVisible')).toBe(false);
      });
    });

    describe('when "pendingIssuableRemoveRequest" event is emitted', () => {
      beforeEach(async () => {
        createComponent();
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: [issuable1.reference],
          touchedReference: '',
        });
      });

      it('removes pending related issue', async () => {
        expect(findRelatedIssuesBlock().props('pendingReferences')).toHaveLength(1);

        await findRelatedIssuesBlock().vm.$emit('pendingIssuableRemoveRequest', 0);

        expect(findRelatedIssuesBlock().props('pendingReferences')).toHaveLength(0);
      });
    });

    describe('when "addIssuableFormSubmit" event is emitted', () => {
      beforeEach(async () => {
        await createComponent();
        createAlert.mockClear();
      });

      it('processes references before submitting', async () => {
        const input = '#123';
        const linkedIssueType = linkedIssueTypesMap.RELATES_TO;
        const emitObj = {
          pendingReferences: input,
          linkedIssueType,
        };
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormSubmit', emitObj);
        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([input]);
      });

      it('submits zero pending issues as related issue', async () => {
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormSubmit', {});
        await waitForPromises();

        expect(findRelatedIssuesBlock().props('pendingReferences')).toHaveLength(0);
        expect(findRelatedIssuesBlock().props('relatedIssues')).toHaveLength(0);
      });

      it('submits pending issue as related issue', async () => {
        mock.onPost(defaultProps.endpoint).reply(HTTP_STATUS_OK, {
          issuables: [issuable1],
          result: {
            message: 'something was successfully related',
            status: 'success',
          },
        });
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: [issuable1],
          touchedReference: '',
        });
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormSubmit', {});
        await waitForPromises();

        expect(findRelatedIssuesBlock().props('pendingReferences')).toHaveLength(0);
        expect(findRelatedIssuesBlock().props('relatedIssues')).toEqual([
          expect.objectContaining({ id: issuable1.id }),
        ]);
      });

      it('submits multiple pending issues as related issues', async () => {
        mock.onPost(defaultProps.endpoint).reply(HTTP_STATUS_OK, {
          issuables: [issuable1, issuable2],
          result: {
            message: 'something was successfully related',
            status: 'success',
          },
        });
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: [issuable1.reference, issuable2.reference],
          touchedReference: '',
        });
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormSubmit', {});
        await waitForPromises();

        expect(findRelatedIssuesBlock().props('pendingReferences')).toHaveLength(0);
        expect(findRelatedIssuesBlock().props('relatedIssues')).toEqual([
          expect.objectContaining({ id: issuable1.id }),
          expect.objectContaining({ id: issuable2.id }),
        ]);
      });

      it('passes an error message from the backend upon error', async () => {
        const input = '#123';
        const message = 'error';
        mock.onPost(defaultProps.endpoint).reply(HTTP_STATUS_CONFLICT, { message });
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: [issuable1.reference, issuable2.reference],
          touchedReference: '',
        });

        expect(findRelatedIssuesBlock().props('hasError')).toBe(false);
        expect(findRelatedIssuesBlock().props('itemAddFailureMessage')).toBe(null);

        await findRelatedIssuesBlock().vm.$emit('addIssuableFormSubmit', input);
        await waitForPromises();

        expect(findRelatedIssuesBlock().props('hasError')).toBe(true);
        expect(findRelatedIssuesBlock().props('itemAddFailureMessage')).toBe(message);
      });
    });

    describe('when "addIssuableFormCancel" event is emitted', () => {
      beforeEach(() => createComponent({ data: { isFormVisible: true, inputValue: 'foo' } }));

      it('hides form and resets input', async () => {
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormCancel');

        expect(findRelatedIssuesBlock().props('isFormVisible')).toBe(false);
        expect(findRelatedIssuesBlock().props('inputValue')).toBe('');
        expect(findRelatedIssuesBlock().props('pendingReferences')).toHaveLength(0);
      });
    });

    describe('when "addIssuableFormInput" event is emitted', () => {
      it('updates pending references with issue reference', async () => {
        const input = '#123 ';
        createComponent();

        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: [input.trim()],
          touchedReference: input,
        });

        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([input.trim()]);
      });

      it('updates pending references with full reference', async () => {
        const input = 'asdf/qwer#444 ';
        createComponent();

        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: [input.trim()],
          touchedReference: input,
        });

        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([input.trim()]);
      });

      it('updates pending references with issue link', async () => {
        const link = 'http://localhost:3000/foo/bar/issues/111';
        const input = `${link} `;
        createComponent();

        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: [input.trim()],
          touchedReference: input,
        });

        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([link]);
      });

      it('updates pending references with multiple references', async () => {
        const input = 'asdf/qwer#444 #12 ';
        createComponent();

        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: input.trim().split(/\s/),
          touchedReference: '2',
        });

        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([
          'asdf/qwer#444',
          '#12',
        ]);
      });

      it('updates pending references with invalid values', async () => {
        const input = 'something random ';
        createComponent();

        await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
          untouchedRawReferences: input.trim().split(/\s/),
          touchedReference: '2',
        });

        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([
          'something',
          'random',
        ]);
      });

      it.each(['#', '&'])(
        'prepends %s when user enters a numeric value [0-9]',
        async (pathIdSeparator) => {
          const input = '23';
          createComponent({ props: { pathIdSeparator } });

          await findRelatedIssuesBlock().vm.$emit('addIssuableFormInput', {
            untouchedRawReferences: input.trim().split(/\s/),
            touchedReference: input,
          });

          expect(findRelatedIssuesBlock().props('inputValue')).toBe(`${pathIdSeparator}${input}`);
        },
      );
    });

    describe('when "addIssuableFormBlur" event is emitted', () => {
      beforeEach(() => {
        createComponent();
      });

      it('adds any references to pending when blurring', async () => {
        const input = '#123';
        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([]);
        await findRelatedIssuesBlock().vm.$emit('addIssuableFormBlur', input);
        expect(findRelatedIssuesBlock().props('pendingReferences')).toEqual([input]);
      });
    });
  });
});
