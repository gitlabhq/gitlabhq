---
stage: Systems
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---


# Geo glossary

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

NOTE:
We are updating the Geo documentation, user interface and commands to reflect these changes. Not all pages comply with
these definitions yet.

 These are the defined terms to describe all aspects of Geo. Using a set of clearly
 defined terms helps us to communicate efficiently and avoids confusion. The language
 on this page aims to be [ubiquitous](https://handbook.gitlab.com/handbook/communication/#ubiquitous-language)
 and [as simple as possible](https://handbook.gitlab.com/handbook/communication/#simple-language).

 We provide example diagrams and statements to demonstrate correct usage of terms.

| Term                   | Definition                                                                                                                                                                                | Scope        | Discouraged synonyms                            |
|------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------|-------------------------------------------------|
| Node                   | An individual server that runs GitLab either with a specific role or as a whole (for example a Rails application node). In a cloud context this can be a specific machine type.           | GitLab       | instance, server                                |
| Site                   | One or a collection of nodes running a single GitLab application. A site can be single-node or multi-node.                                                                                | GitLab       | deployment, installation instance               |
| Single-node site       | A specific configuration of GitLab that uses exactly one node.                                                                                                                            | GitLab       | single-server, single-instance                  |
| Multi-node site        | A specific configuration of GitLab that uses more than one node.                                                                                                                          | GitLab       | multi-server, multi-instance, high availability |
| Primary site           | A GitLab site whose data is being replicated by at least one secondary site. There can only be a single primary site.                                                                     | Geo-specific | Geo deployment, Primary node                    |
| Secondary site         | A GitLab site that is configured to replicate the data of a primary site. There can be one or more secondary sites.                                                                       | Geo-specific | Geo deployment, Secondary node                  |
| Geo deployment         | A collection of two or more GitLab sites with exactly one primary site being replicated by one or more secondary sites.                                                                   | Geo-specific |                                                 |
| Reference architecture | A [specified configuration of GitLab based on Requests per Second or user count](../reference_architectures/_index.md), possibly including multiple nodes and multiple sites.                                   | GitLab       |                                                 |
| Promoting              | Changing the role of a site from secondary to primary.                                                                                                                                    | Geo-specific |                                                 |
| Demoting               | Changing the role of a site from primary to secondary.                                                                                                                                    | Geo-specific |                                                 |
| Failover               | The entire process that shifts users from a primary Site to a secondary site. This includes promoting a secondary, but contains other parts as well. For example, scheduling maintenance. | Geo-specific |                                                 |
| Replication            | Also called "synchronization". The uni-directional process that updates a resource on a secondary site to match the resource on the primary site. | Geo-specific | |
| Verification           | The process of comparing the data that exist on a primary site to the data replicated to a secondary site. Used to ensure integrity of replicated data. | Geo-specific | |
| Unified URL            | A single external URL used for all Geo sites. Allows requests to be routed to either the primary Geo site or any secondary Geo sites. | Geo-specific | |
| Geo proxying           | A mechanism where secondary Geo sites transparently forward operations to the primary site, except for certain operations that can be handled locally by the secondary sites. | Geo-specific | |

## Examples

### Single-node site

```mermaid
 graph TD
   subgraph S-Site[Single-node site]
    Node_3[GitLab node]
  end
```

### Multi-node site

```mermaid
 graph TD
   subgraph MN-Site[Multi-node site]
    Node_1[Application node]
    Node_2[Database node]
    Node_3[Gitaly node]
  end
```

### Geo deployment - Single-node sites

This Geo deployment has a single-node primary site, a single-node secondary site:

```mermaid
 graph TD
   subgraph Geo deployment
   subgraph Primary[Primary site, single-node]
    Node_1[GitLab node]
  end
  subgraph Secondary1[Secondary site 1, single-node]
    Node_2[GitLab node]
   end
   end
```

### Geo deployment - Multi-node sites

This Geo deployment has a multi-node primary site, a multi-node secondary site:

```mermaid
 graph TD
   subgraph Geo deployment
   subgraph Primary[Primary site, multi-node]
    Node_1[Application node]
    Node_2[Database node]
  end
  subgraph Secondary1[Secondary site 1, multi-node]
    Node_5[Application node]
    Node_6[Database node]
   end
   end
```

### Geo deployment - Mixed sites

This Geo deployment has a multi-node primary site, a multi-node secondary site and another single-node secondary site:

```mermaid
 graph TD
   subgraph Geo deployment
   subgraph Primary[Primary site, multi-node]
    Node_1[Application node]
    Node_2[Database node]
    Node_3[Gitaly node]
  end
  subgraph Secondary1[Secondary site 1, multi-node]
    Node_5[Application node]
    Node_6[Database node]
   end
  subgraph Secondary2[Secondary site 2, single-node]
    Node_7[Single GitLab node]
   end
   end
```
