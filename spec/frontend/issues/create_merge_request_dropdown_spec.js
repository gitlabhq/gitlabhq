import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import confidentialState from '~/confidential_merge_request/state';
import CreateMergeRequestDropdown from '~/issues/create_merge_request_dropdown';
import axios from '~/lib/utils/axios_utils';

describe('CreateMergeRequestDropdown', () => {
  let axiosMock;
  let dropdown;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);

    document.body.innerHTML = `
      <div id="dummy-wrapper-element">
        <div class="available"></div>
        <div class="unavailable">
          <div class="js-create-mr-spinner"></div>
          <div class="text"></div>
        </div>
        <div class="js-ref"></div>
        <div class="js-create-mr"></div>
        <div class="js-create-merge-request">
          <span class="js-spinner"></span>
        </div>
        <div class="js-create-target"></div>
        <div class="js-dropdown-toggle"></div>
      </div>
    `;

    const dummyElement = document.getElementById('dummy-wrapper-element');
    dropdown = new CreateMergeRequestDropdown(dummyElement);
    dropdown.refsPath = `${TEST_HOST}/dummy/refs?search=`;
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('getRef', () => {
    it('escapes branch names correctly', async () => {
      const endpoint = `${dropdown.refsPath}contains%23hash`;
      jest.spyOn(axios, 'get');
      axiosMock.onGet(endpoint).replyOnce({});

      await dropdown.getRef('contains#hash');
      expect(axios.get).toHaveBeenCalledWith(
        endpoint,
        expect.objectContaining({ cancelToken: expect.anything() }),
      );
    });
  });

  describe('updateCreatePaths', () => {
    it('escapes branch names correctly', () => {
      dropdown.createBranchPath = `${TEST_HOST}/branches?branch_name=some-branch&issue=42`;
      dropdown.createMrPath = `${TEST_HOST}/create_merge_request?merge_request%5Bsource_branch%5D=test&merge_request%5Btarget_branch%5D=master&merge_request%5Bissue_iid%5D=42`;

      dropdown.updateCreatePaths('branch', 'contains#hash');

      expect(dropdown.createBranchPath).toBe(
        `${TEST_HOST}/branches?branch_name=contains%23hash&issue=42`,
      );

      expect(dropdown.createMrPath).toBe(
        `${TEST_HOST}/create_merge_request?merge_request%5Bsource_branch%5D=contains%23hash&merge_request%5Btarget_branch%5D=master&merge_request%5Bissue_iid%5D=42`,
      );

      expect(dropdown.wrapperEl.dataset.createBranchPath).toBe(
        `${TEST_HOST}/branches?branch_name=contains%23hash&issue=42`,
      );

      expect(dropdown.wrapperEl.dataset.createMrPath).toBe(
        `${TEST_HOST}/create_merge_request?merge_request%5Bsource_branch%5D=contains%23hash&merge_request%5Btarget_branch%5D=master&merge_request%5Bissue_iid%5D=42`,
      );
    });
  });

  describe('enable', () => {
    beforeEach(() => {
      dropdown.createMergeRequestButton.classList.add('disabled');
    });

    afterEach(() => {
      confidentialState.selectedProject = {};
    });

    it('enables button when not confidential issue', () => {
      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).not.toContain('disabled');
    });

    it('enables when can create confidential issue', () => {
      document.querySelector('.js-create-mr').dataset.isConfidential = 'true';
      confidentialState.selectedProject = { name: 'test' };

      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).not.toContain('disabled');
    });

    it('does not enable when can not create confidential issue', () => {
      document.querySelector('.js-create-mr').dataset.isConfidential = 'true';

      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).toContain('disabled');
    });
  });

  describe('setLoading', () => {
    it.each`
      loading  | hasClass
      ${true}  | ${false}
      ${false} | ${true}
    `('toggle loading spinner when loading is $loading', ({ loading, hasClass }) => {
      dropdown.setLoading(loading);

      expect(document.querySelector('.js-spinner').classList.contains('gl-display-none')).toEqual(
        hasClass,
      );
    });
  });
});
