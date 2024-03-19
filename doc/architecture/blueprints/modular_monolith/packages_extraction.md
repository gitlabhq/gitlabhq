---
status: proposed
creation-date: "2023-09-29"
authors: [ "@fabiopitino" ]
coach: [ ]
approvers: [ ]
owning-stage: ""
---

# Convert domain module into packages

The general steps of refactoring existing code to modularization could be:

1. Use the same namespace for all classes and modules related to the same [bounded context](bounded_contexts.md).

   - **Why?** Without even a rough understanding of the domains at play in the codebase it is difficult to draw a plan.
     Having well namespaced code that everyone else can follow is also the pre-requisite for modularization.
   - If a domain is already well namespaced and no similar or related namespaces exist, we can move directly to the
     next step.
1. Prepare Rails development for Packwerk packages. This is a **once off step** with maybe some improvements
   added over time.

   - We will have the Rails autoloader to work with Packwerk's directory structure, as demonstrated in
     [this PoC](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129254/diffs#note_1512982957).
   - We will have [Danger-Packwerk](https://github.com/rubyatscale/danger-packwerk) running in CI for merge requests.
   - We will possibly have Packer check running in Lefthook on pre-commit or pre-push.
1. Move file into a Packwerk package.

   - This should consist in creating a Packwerk package and iteratively move files into the package.
   - Constants are auto-loaded correctly whether they are in `app/` or `lib/` inside a Packwerk package.
   - This is a phase where the domain code will be split between the package directory and the Rails directory structure.
     **We must move quickly here**.
1. Enforce namespace boundaries by requiring packages declare their [dependencies explicitly](https://github.com/Shopify/packwerk/blob/main/USAGE.md#enforcing-dependency-boundary)
   and only depend on other packages' [public interface](https://github.com/rubyatscale/packwerk-extensions#privacy-checker).

   - **Why?** Up until now all constants would be public since we have not enforced privacy. By moving existing files
     into packages without enforcing boundaries we can focus on wrapping a namespace in a package without being distracted
     by Packwer privacy violations. By enforcing privacy afterwards we gain an understanding of coupling between various
     constants and domains.
   - This way we know what constants need to be made public (as they are used by other packages) and what can
     remain private (taking the benefit of encapsulation). We will use Packwerk's recorded violations (like Rubocop TODOs)
     to refactor the code over time.
   - We can update the dependency graph to see where it fit in the overall architecture.
1. Work off Packwerk's recorded violations to make refactorings. **This is a long term phase** that the DRIs of the
   domain need to nurture over time. We will use Packwerk failures and the dependency diagram to influence the modular design.

   - Revisit wheteher a class should be private instead of public, and crate a better interface.
   - Move constants to different package if too coupled with that.
   - Join packages if they are too coupled to each other.

Once we have Packwerk configured for the Rails application (step 2 above), emerging domains could be directly implemented
as Packwerk packages, benefiting from isolation and clear interface immediately.
