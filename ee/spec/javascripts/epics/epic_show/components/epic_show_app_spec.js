import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import epicShowApp from 'ee/epics/epic_show/components/epic_show_app.vue';
import epicHeader from 'ee/epics/epic_show/components/epic_header.vue';
import { stateEvent } from 'ee/epics/constants';
import issuableApp from '~/issue_show/components/app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import issueShowData from 'spec/issue_show/mock_data';
import { props } from '../mock_data';

// eslint-disable-next-line
fdescribe('EpicShowApp', () => {
  let mock;
  let vm;
  let headerVm;
  let issuableAppVm;

  beforeEach((done) => {
    mock = new MockAdapter(axios);
    mock.onGet('/realtime_changes').reply(200, issueShowData.initialRequest);

    const {
      canUpdate,
      canDestroy,
      endpoint,
      updateEndpoint,
      initialTitleHtml,
      initialTitleText,
      markdownPreviewPath,
      markdownDocsPath,
      author,
      created,
      toggleSubscriptionPath,
      state,
      open,
    } = props;

    const EpicShowApp = Vue.extend(epicShowApp);
    vm = mountComponent(EpicShowApp, props);

    const EpicHeader = Vue.extend(epicHeader);
    headerVm = mountComponent(EpicHeader, {
      author,
      created,
      open,
      canUpdate,
    });

    const IssuableApp = Vue.extend(issuableApp);
    issuableAppVm = mountComponent(IssuableApp, {
      canUpdate,
      canDestroy,
      endpoint,
      updateEndpoint,
      issuableRef: '',
      initialTitleHtml,
      initialTitleText,
      initialDescriptionHtml: '',
      initialDescriptionText: '',
      markdownPreviewPath,
      markdownDocsPath,
      projectPath: props.groupPath,
      projectNamespace: '',
      showInlineEditButton: true,
      toggleSubscriptionPath,
      state,
    });

    setTimeout(done);
  });

  afterEach(() => {
    mock.restore();
  });

  it('should render epic-header', () => {
    expect(vm.$el.innerHTML.indexOf(headerVm.$el.innerHTML) !== -1).toEqual(true);
  });

  it('should render issuable-app', () => {
    expect(vm.$el.innerHTML.indexOf(issuableAppVm.$el.innerHTML) !== -1).toEqual(true);
  });

  it('should render epic-sidebar', () => {
    expect(vm.$el.querySelector('aside.right-sidebar.epic-sidebar')).not.toBe(null);
  });

  it('calls `updateStatus` with stateEventType param on service and triggers document events when request is successful', done => {
    const queryParam = `epic[state_event]=${stateEvent.close}`;
    mock.onPut(`${vm.endpoint}.json?${encodeURI(queryParam)}`).reply(200, {});
    spyOn(vm.service, 'updateStatus').and.callThrough();
    spyOn(vm, 'triggerDocumentEvent');

    vm.toggleEpicStatus(stateEvent.close);
    setTimeout(() => {
      expect(vm.service.updateStatus).toHaveBeenCalledWith(stateEvent.close);
      expect(vm.triggerDocumentEvent).toHaveBeenCalledWith('issuable_vue_app:change', true);
      expect(vm.triggerDocumentEvent).toHaveBeenCalledWith('issuable:change', true);
      done();
    }, 0);
  });

  it('calls `updateStatus` with stateEventType param on service and shows flash error and triggers document events when request is failed', done => {
    const queryParam = `epic[state_event]=${stateEvent.close}`;
    mock.onPut(`${vm.endpoint}.json?${encodeURI(queryParam)}`).reply(500, {});
    spyOn(vm.service, 'updateStatus').and.callThrough();
    spyOn(vm, 'triggerDocumentEvent');

    vm.toggleEpicStatus(stateEvent.close);
    setTimeout(() => {
      expect(vm.service.updateStatus).toHaveBeenCalledWith(stateEvent.close);
      expect(vm.triggerDocumentEvent).toHaveBeenCalledWith('issuable_vue_app:change', false);
      expect(vm.triggerDocumentEvent).toHaveBeenCalledWith('issuable:change', false);
      done();
    }, 0);
  });
});
