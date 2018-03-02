import initNewEpic from 'ee/epics/new_epic/new_epic_bundle';
import initRoadmap from 'ee/roadmap/index';

document.addEventListener('DOMContentLoaded', () => {
  initNewEpic();
  initRoadmap();
});
