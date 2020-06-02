import { uniqWith, isEqual } from 'lodash';

/*
    The following functions are the main engine in transforming the data as
    received from the endpoint into the format the d3 graph expects.

    Input is of the form:
    [stages]
      stages: {name, groups}
        groups: [{ name, size, jobs }]
          name is a group name; in the case that the group has one job, it is
            also the job name
          size is the number of parallel jobs
          jobs: [{ name, needs}]
            job name is either the same as the group name or group x/y

    Output is of the form:
    { nodes: [node], links: [link] }
      node: { name, category }, + unused info passed through
      link: { source, target, value }, with source & target being node names
        and value being a constant

    We create nodes, create links, and then dedupe the links, so that in the case where
    job 4 depends on job 1 and job 2, and job 2 depends on job 1, we show only a single link
    from job 1 to job 2 then another from job 2 to job 4.

    CREATE NODES
    stage.name -> node.category
    stage.group.name -> node.name (this is the group name if there are parallel jobs)
    stage.group.jobs -> node.jobs
    stage.group.size -> node.size

    CREATE LINKS
    stages.groups.name -> target
    stages.groups.needs.each -> source (source is the name of the group, not the parallel job)
    10 -> value (constant)
  */

export const createNodes = data => {
  return data.flatMap(({ groups, name }) => {
    return groups.map(group => {
      return { ...group, category: name };
    });
  });
};

export const createNodeDict = nodes => {
  return nodes.reduce((acc, node) => {
    const newNode = {
      ...node,
      needs: node.jobs.map(job => job.needs || []).flat(),
    };

    if (node.size > 1) {
      node.jobs.forEach(job => {
        acc[job.name] = newNode;
      });
    }

    acc[node.name] = newNode;
    return acc;
  }, {});
};

export const createNodesStructure = data => {
  const nodes = createNodes(data);
  const nodeDict = createNodeDict(nodes);

  return { nodes, nodeDict };
};

export const makeLinksFromNodes = (nodes, nodeDict) => {
  const constantLinkValue = 10; // all links are the same weight
  return nodes
    .map(group => {
      return group.jobs.map(job => {
        if (!job.needs) {
          return [];
        }

        return job.needs.map(needed => {
          return {
            source: nodeDict[needed]?.name,
            target: group.name,
            value: constantLinkValue,
          };
        });
      });
    })
    .flat(2);
};

export const getAllAncestors = (nodes, nodeDict) => {
  const needs = nodes
    .map(node => {
      return nodeDict[node].needs || '';
    })
    .flat()
    .filter(Boolean);

  if (needs.length) {
    return [...needs, ...getAllAncestors(needs, nodeDict)];
  }

  return [];
};

export const filterByAncestors = (links, nodeDict) =>
  links.filter(({ target, source }) => {
    /*

    for every link, check out it's target
    for every target, get the target node's needs
    then drop the current link source from that list

    call a function to get all ancestors, recursively
    is the current link's source in the list of all parents?
    then we drop this link

  */
    const targetNode = target;
    const targetNodeNeeds = nodeDict[targetNode].needs;
    const targetNodeNeedsMinusSource = targetNodeNeeds.filter(need => need !== source);

    const allAncestors = getAllAncestors(targetNodeNeedsMinusSource, nodeDict);
    return !allAncestors.includes(source);
  });

export const parseData = data => {
  const { nodes, nodeDict } = createNodesStructure(data);
  const allLinks = makeLinksFromNodes(nodes, nodeDict);
  const filteredLinks = filterByAncestors(allLinks, nodeDict);
  const links = uniqWith(filteredLinks, isEqual);

  return { nodes, links };
};

/*
  The number of nodes in the most populous generation drives the height of the graph.
*/

export const getMaxNodes = nodes => {
  const counts = nodes.reduce((acc, { layer }) => {
    if (!acc[layer]) {
      acc[layer] = 0;
    }

    acc[layer] += 1;

    return acc;
  }, []);

  return Math.max(...counts);
};

/*
  Because we cannot know if a node is part of a relationship until after we
  generate the links with createSankey, this function is used after the first call
  to find nodes that have no relations.
*/

export const removeOrphanNodes = sankeyfiedNodes => {
  return sankeyfiedNodes.filter(node => node.sourceLinks.length || node.targetLinks.length);
};
