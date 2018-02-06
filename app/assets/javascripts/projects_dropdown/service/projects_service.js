import _ from 'underscore';
import Vue from 'vue';
import VueResource from 'vue-resource';

import bp from '../../breakpoints';
import Api from '../../api';
import AccessorUtilities from '../../lib/utils/accessor';

import { FREQUENT_PROJECTS, HOUR_IN_MS, STORAGE_KEY } from '../constants';

Vue.use(VueResource);

export default class ProjectsService {
  constructor(currentUserName) {
    this.isLocalStorageAvailable = AccessorUtilities.isLocalStorageAccessSafe();
    this.currentUserName = currentUserName;
    this.storageKey = `${this.currentUserName}/${STORAGE_KEY}`;
    this.projectsPath = Vue.resource(Api.buildUrl(Api.projectsPath));
  }

  getSearchedProjects(searchQuery) {
    return this.projectsPath.get({
      simple: true,
      per_page: 20,
      membership: !!gon.current_user_id,
      order_by: 'last_activity_at',
      search: searchQuery,
    });
  }

  getFrequentProjects() {
    if (this.isLocalStorageAvailable) {
      return this.getTopFrequentProjects();
    }
    return null;
  }

  logProjectAccess(project) {
    let matchFound = false;
    let storedFrequentProjects;

    if (this.isLocalStorageAvailable) {
      const storedRawProjects = localStorage.getItem(this.storageKey);

      // Check if there's any frequent projects list set
      if (!storedRawProjects) {
        // No frequent projects list set, set one up.
        storedFrequentProjects = [];
        storedFrequentProjects.push({ ...project, frequency: 1 });
      } else {
        // Check if project is already present in frequents list
        // When found, update metadata of it.
        storedFrequentProjects = JSON.parse(storedRawProjects).map((projectItem) => {
          if (projectItem.id === project.id) {
            matchFound = true;
            const diff = Math.abs(project.lastAccessedOn - projectItem.lastAccessedOn) / HOUR_IN_MS;
            const updatedProject = {
              ...project,
              frequency: projectItem.frequency,
              lastAccessedOn: projectItem.lastAccessedOn,
            };

            // Check if duration since last access of this project
            // is over an hour
            if (diff > 1) {
              return {
                ...updatedProject,
                frequency: updatedProject.frequency + 1,
                lastAccessedOn: Date.now(),
              };
            }

            return {
              ...updatedProject,
            };
          }

          return projectItem;
        });

        // Check whether currently logged project is present in frequents list
        if (!matchFound) {
          // We always keep size of frequents collection to 20 projects
          // out of which only 5 projects with
          // highest value of `frequency` and most recent `lastAccessedOn`
          // are shown in projects dropdown
          if (storedFrequentProjects.length === FREQUENT_PROJECTS.MAX_COUNT) {
            storedFrequentProjects.shift(); // Remove an item from head of array
          }

          storedFrequentProjects.push({ ...project, frequency: 1 });
        }
      }

      localStorage.setItem(this.storageKey, JSON.stringify(storedFrequentProjects));
    }
  }

  getTopFrequentProjects() {
    const storedFrequentProjects = JSON.parse(localStorage.getItem(this.storageKey));
    let frequentProjectsCount = FREQUENT_PROJECTS.LIST_COUNT_DESKTOP;

    if (!storedFrequentProjects) {
      return [];
    }

    if (bp.getBreakpointSize() === 'sm' ||
        bp.getBreakpointSize() === 'xs') {
      frequentProjectsCount = FREQUENT_PROJECTS.LIST_COUNT_MOBILE;
    }

    const frequentProjects = storedFrequentProjects
      .filter(project => project.frequency >= FREQUENT_PROJECTS.ELIGIBLE_FREQUENCY);

    // Sort all frequent projects in decending order of frequency
    // and then by lastAccessedOn with recent most first
    frequentProjects.sort((projectA, projectB) => {
      if (projectA.frequency < projectB.frequency) {
        return 1;
      } else if (projectA.frequency > projectB.frequency) {
        return -1;
      } else if (projectA.lastAccessedOn < projectB.lastAccessedOn) {
        return 1;
      } else if (projectA.lastAccessedOn > projectB.lastAccessedOn) {
        return -1;
      }

      return 0;
    });

    return _.first(frequentProjects, frequentProjectsCount);
  }
}
