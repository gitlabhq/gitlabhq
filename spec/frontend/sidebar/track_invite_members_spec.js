import $ from 'jquery';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import trackShowInviteMemberLink from '~/sidebar/track_invite_members';

describe('Track user dropdown open', () => {
  let trackingSpy;
  let dropdownElement;

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="dummy-wrapper-element">
        <div class="js-sidebar-assignee-dropdown">
          <div class="js-invite-members-track" data-track-action="_track_event_" data-track-label="_track_label_">
          </div>
        </div>
      </div>
    `;

    dropdownElement = document.querySelector('.js-sidebar-assignee-dropdown');
    trackingSpy = mockTracking('_category_', dropdownElement, jest.spyOn);
    document.body.dataset.page = 'some:page';

    trackShowInviteMemberLink(dropdownElement);
  });

  afterEach(() => {
    unmockTracking();
  });

  it('sends a tracking event when the dropdown is opened and contains Invite Members link', () => {
    $(dropdownElement).trigger('shown.bs.dropdown');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, '_track_event_', {
      label: '_track_label_',
    });
  });
});
