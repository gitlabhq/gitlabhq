import $ from 'jquery';
import KubernetesLogs from 'ee/kubernetes_logs';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { logMockData, podMockData } from './kubernetes_mock_data';

describe('Kubernetes Logs', () => {
  const fixtureTemplate = 'static/environments_logs.html.raw';
  const mockPodName = 'production-tanuki-1';
  const logMockPath = '/root/kubernetes-app/environments/1/logs';
  let kubernetesLogContainer;
  let kubernetesLog;
  let mock;
  preloadFixtures(fixtureTemplate);

  describe('When data is requested correctly', () => {
    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => [mockPodName]);

      mock = new MockAdapter(axios);

      mock.onGet(logMockPath).reply(200, { logs: logMockData, pods: podMockData });

      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
    });

    afterEach(() => {
      mock.restore();
    });

    it('has the pod name placed on the dropdown', (done) => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      kubernetesLog.getPodLogs();

      setTimeout(() => {
        const podDropdown = document
          .querySelector('.js-pod-dropdown')
          .querySelector('.dropdown-menu-toggle');

        expect(podDropdown.textContent).toContain(mockPodName);
        done();
      }, 0);
    });

    it('queries the pod log data and sets the dom elements', (done) => {
      const scrollSpy = spyOnDependency(KubernetesLogs, 'scrollDown').and.callThrough();
      const toggleDisableSpy = spyOnDependency(KubernetesLogs, 'toggleDisableButton').and.stub();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      kubernetesLog.getPodLogs();
      setTimeout(() => {
        expect(kubernetesLog.isLogComplete).toEqual(true);
        expect(kubernetesLog.$buildOutputContainer.text()).toContain(logMockData[0].trim());
        expect(scrollSpy).toHaveBeenCalled();
        expect(toggleDisableSpy).toHaveBeenCalled();
        done();
      }, 0);
    });

    it('asks for the pod logs from another pod', (done) => {
      const changePodLogSpy = spyOn(KubernetesLogs.prototype, 'getPodLogs').and.callThrough();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      kubernetesLog.getPodLogs();
      setTimeout(() => {
        const podDropdown = document.querySelectorAll('.js-pod-dropdown .dropdown-menu button');
        const anotherPod = podDropdown[podDropdown.length - 1];

        anotherPod.click();

        expect(changePodLogSpy).toHaveBeenCalled();
        done();
      }, 0);
    });

    it('clears the pod dropdown contents when pod logs are requested', (done) => {
      const emptySpy = spyOn($.prototype, 'empty').and.callThrough();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      kubernetesLog.getPodLogs();
      setTimeout(() => {
        // This is because it clears both the job log contents and the dropdown
        expect(emptySpy.calls.count()).toEqual(2);
        done();
      });
    });
  });

  describe('XSS Protection', () => {
    const hackyPodName = '">&lt;img src=x onerror=alert(document.domain)&gt; production';
    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      spyOnDependency(KubernetesLogs, 'getParameterValues').and.callFake(() => [hackyPodName]);

      mock = new MockAdapter(axios);

      mock.onGet(logMockPath).reply(200, { logs: logMockData, pods: [hackyPodName] });

      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
    });

    afterEach(() => {
      mock.restore();
    });

    it('escapes the pod name', () => {
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
      expect(kubernetesLog.podName).toContain('&quot;&gt;&amp;lt;img src=x onerror=alert(document.domain)&amp;gt; production');
    });
  });

  describe('When no pod name is available', () => {
    beforeEach(() => {
      loadFixtures(fixtureTemplate);

      kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
    });

    it('shows up a flash message when no pod name is specified', () => {
      const createFlashSpy = spyOnDependency(KubernetesLogs, 'createFlash').and.stub();
      kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

      expect(createFlashSpy).toHaveBeenCalled();
    });
  });
});
