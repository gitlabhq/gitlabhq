import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import CreateMergeRequestDropdown from '~/create_merge_request_dropdown';
import confidentialState from '~/confidential_merge_request/state';
import { TEST_HOST } from './helpers/test_constants';

describe('CreateMergeRequestDropdown', () => {
  let axiosMock;
  let dropdown;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);

    document.body.innerHTML = `
      <div id="dummy-wrapper-element">
        <div class="available"></div>
        <div class="unavailable">
          <div class="fa"></div>
          <div class="text"></div>
        </div>
        <div class="js-ref"></div>
        <div class="js-create-mr"></div>
        <div class="js-create-merge-request"></div>
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
    it('escapes branch names correctly', done => {
      const endpoint = `${dropdown.refsPath}contains%23hash`;
      jest.spyOn(axios, 'get');
      axiosMock.onGet(endpoint).replyOnce({});

      dropdown
        .getRef('contains#hash')
        .then(() => {
          expect(axios.get).toHaveBeenCalledWith(endpoint);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('updateCreatePaths', () => {
    it('escapes branch names correctly', () => {
      dropdown.createBranchPath = `${TEST_HOST}/branches?branch_name=some-branch&issue=42`;
      dropdown.createMrPath = `${TEST_HOST}/create_merge_request?branch_name=some-branch&ref=master`;

      dropdown.updateCreatePaths('branch', 'contains#hash');

      expect(dropdown.createBranchPath).toBe(
        `${TEST_HOST}/branches?branch_name=contains%23hash&issue=42`,
      );

      expect(dropdown.createMrPath).toBe(
        `${TEST_HOST}/create_merge_request?branch_name=contains%23hash&ref=master`,
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
      document.querySelector('.js-create-mr').setAttribute('data-is-confidential', 'true');
      confidentialState.selectedProject = { name: 'test' };

      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).not.toContain('disabled');
    });

    it('does not enable when can not create confidential issue', () => {
      document.querySelector('.js-create-mr').setAttribute('data-is-confidential', 'true');

      dropdown.enable();

      expect(dropdown.createMergeRequestButton.classList).toContain('disabled');
    });
  });
});
